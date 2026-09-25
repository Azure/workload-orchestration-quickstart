targetScope = 'resourceGroup'

type AIOTarget = {
  name: string
  resourceGroupName: string
  configuration: object
}

param contextName string = 'default'
param capability string = 'aio'
param hierarchy string = 'line'
param schemaRegistryId string
param adrNamespaceId string
param targets AIOTarget[]

resource context 'Microsoft.Edge/contexts@2026-03-01' = {
  name: contextName
  location: resourceGroup().location
  properties: {
    capabilities: [
      {
        name: capability
        description: capability
      }
    ]
    hierarchies: [
      {
        name: hierarchy
        description: hierarchy
      }
    ]
  }
}

var targetResourceGroups = [for target in targets: toLower(target.resourceGroupName)]
var siteResourceGroups = union([toLower(resourceGroup().name)], targetResourceGroups)

resource clusters 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = [for target in targets: {
  name: target.configuration.clusterName
  scope: resourceGroup(target.resourceGroupName)
}]

resource cloudTargets 'Microsoft.Edge/targets@2026-05-01-preview' existing = [for target in targets: {
  scope: resourceGroup(target.resourceGroupName)
  name: target.name
}]

var aioConfigTemplate = '''
configs:
  clusterName: ${{$val(clusterName)}}
  customLocationName: ${{$val(customLocationName)}}
  aioInstanceName: ${{$val(aioInstanceName)}}
  clusterLocation: ${{$val(clusterLocation)}}
'''

@onlyIfNotExists()
resource configTemplate 'Microsoft.Edge/configTemplates@2026-05-01-preview' = {
  name: 'aio-config'
  location: resourceGroup().location
  properties: {
    description: 'Configuration template for cloud target'
  }
}

resource configTemplateMetadata 'Microsoft.Edge/configTemplates/configTemplateMetadatas@2026-05-01-preview' = {
  parent: configTemplate
  name: 'config-metadata'
  dependsOn: [
    groups
  ]
  properties: {
    templateUniqueIdentifier: configTemplate.properties.uniqueIdentifier
    linkedHierarchies: [
      {
        level: hierarchy
        hierarchyIds: [for (target, i) in targets: cloudTargets[i].id]
      }
    ]
    contextId: context.id
  }
}

@onlyIfNotExists()
resource configTemplateVersion 'Microsoft.Edge/configTemplates/versions@2026-05-01-preview' = {
  parent: configTemplate
  name: '1.0.0'
  properties: {
    configurations: aioConfigTemplate
  }
}

var configTemplateReference = '${configTemplate.name}/${configTemplateVersion.name}'

module groups 'modules/cloud-target.bicep' = [for siteResourceGroup in siteResourceGroups: {
  name: 'aio-target-${take(siteResourceGroup, 38)}-${uniqueString(siteResourceGroup)}'
  scope: resourceGroup(siteResourceGroup)
  dependsOn: [
    configTemplateVersion
  ]
  params: {
    contextSubscriptionId: subscription().subscriptionId
    contextResourceGroup: resourceGroup().name
    contextName: context.name
    contextId: context.id
    capability: capability
    hierarchy: hierarchy
    configTemplateUid: configTemplate.properties.uniqueIdentifier
    targets: filter(targets, target => toLower(target.resourceGroupName) == siteResourceGroup)
    targetIndices: filter(range(0, length(targets)), i => toLower(targets[i].resourceGroupName) == siteResourceGroup)
    clusterLocations: [for (target, i) in targets: clusters[i].location]
  }
}]

@onlyIfNotExists()
resource aioOpEnablementSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: 'aio-op-enablement-spec'
  location: resourceGroup().location
  properties: {
    description: 'Template spec'
  }

  @onlyIfNotExists()
  resource version 'versions@2022-02-01' = {
    name: '1.0'
    location: resourceGroup().location
    properties: {
      mainTemplate: loadJsonContent('./AioOnboardingTemplates/azure-iot-operations-enablement.json')
    }
  }
}

@onlyIfNotExists()
resource opEnablement 'Microsoft.Edge/solutionTemplates@2026-05-01-preview' = {
  name: 'aio-enablement'
  location: resourceGroup().location
  properties: {
    description: 'Enable Azure IoT Operations prerequisites on an Arc-connected Kubernetes cluster'
    capabilities: [
      capability
    ]
  }

  @onlyIfNotExists()
  resource version 'versions@2026-05-01-preview' = {
    name: '1.0.0'
    dependsOn: [
      aioOpEnablementSpec::version
      configTemplateVersion
    ]
    properties: {
      configurations: {
        configs: {
          clusterName: '\${{$config(${configTemplateReference}, clusterName)}}'
        }
      }
      specification: {
        components: [
          {
            name: opEnablement.name
            type: 'armtemplate'
            properties: {
              template: {
                name: aioOpEnablementSpec.name
                version: aioOpEnablementSpec::version.name
              }
            }
          }
        ]
      }
    }
  }
}

@onlyIfNotExists()
resource aioOpInstanceSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: 'aio-op-instance-spec'
  location: resourceGroup().location
  properties: {
    description: 'Template spec'
  }

  @onlyIfNotExists()
  resource version 'versions@2022-02-01' = {
    name: '1.0'
    location: resourceGroup().location
    properties: {
      mainTemplate: loadJsonContent('./AioOnboardingTemplates/azure-iot-operations-instance.json')
    }
  }
}

@onlyIfNotExists()
resource opInstance 'Microsoft.Edge/solutionTemplates@2026-05-01-preview' = {
  name: 'aio-instance'
  location: resourceGroup().location
  properties: {
    description: 'Deploy an Azure IoT Operations Instance and Custom Location'
    capabilities: [
      capability
    ]
  }

  @onlyIfNotExists()
  resource version 'versions@2026-05-01-preview' = {
    name: '1.0.0'
    dependsOn: [
      aioOpInstanceSpec::version
      configTemplateVersion
    ]
    properties: {
      configurations: {
        configs: {
          customLocationName: '\${{$config(${configTemplateReference}, customLocationName)}}'
          aioInstanceName: '\${{$config(${configTemplateReference}, aioInstanceName)}}'
          clusterName: '\${{$config(${configTemplateReference}, clusterName)}}'
          clusterLocation: '\${{$config(${configTemplateReference}, clusterLocation)}}'
          userAssignedIdentity: null
          schemaRegistryId: schemaRegistryId
          adrNamespaceId: adrNamespaceId
          features: null
          brokerConfig: null
        }
      }
      specification: {
        components: [
          {
            name: opInstance.name
            type: 'armtemplate'
            properties: {
              template: {
                name: aioOpInstanceSpec.name
                version: aioOpInstanceSpec::version.name
              }
            }
          }
        ]
      }
    }
  }
}

resource opEnablementDeployments 'Microsoft.Edge/solutionDeployments@2026-05-01-preview' = [for (target, i) in targets: {
  name: '${target.name}-enablement'
  location: resourceGroup().location
  dependsOn: [
    opEnablement::version
    configTemplateMetadata
  ]
  properties: {
    solutionTemplateProperties: {
      name: 'aio-enablement'
      version: '1.0.0'
    }
    targetProperties: {
      targetIds: [
        cloudTargets[i].id
      ]
    }
  }
}]

resource opInstanceDeployments 'Microsoft.Edge/solutionDeployments@2026-05-01-preview' = [for (target, i) in targets: {
  name: '${target.name}-instance'
  location: resourceGroup().location
  dependsOn: [
    opInstance::version
    configTemplateMetadata
    opEnablementDeployments
  ]
  properties: {
    solutionTemplateProperties: {
      name: 'aio-instance'
      version: '1.0.0'
    }
    targetProperties: {
      targetIds: [
        cloudTargets[i].id
      ]
    }
    input: {
      clExtensionIds: opEnablementDeployments[i].properties.output.deploymentResults[0].properties.clExtensionIds
    }
  }
}]
