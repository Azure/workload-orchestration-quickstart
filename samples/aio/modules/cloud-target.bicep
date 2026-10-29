targetScope = 'resourceGroup'

type GroupTarget = {
  name: string
  resourceGroupName: string
  configuration: object
}

param contextSubscriptionId string
param contextResourceGroup string
param contextName string
param contextId string
param capability string
param hierarchy string
param configTemplateUid string
param targets GroupTarget[]
param targetIndices int[]
param clusterLocations string[]

@onlyIfNotExists()
resource site 'Microsoft.Edge/sites@2025-06-01' = {
  name: resourceGroup().name
  properties: {
    displayName: resourceGroup().name
    description: 'AIO site'
    siteAddress: {
      streetAddress1: '1 Microsoft Way'
      city: 'Redmond'
      stateOrProvince: 'WA'
      country: 'US'
      postalCode: '98052'
    }
  }
}

module siteReference 'site-reference.bicep' = {
  name: 'aio-site-${uniqueString(site.id)}'
  scope: resourceGroup(contextSubscriptionId, contextResourceGroup)
  params: {
    contextName: contextName
    referenceName: 'aio-${uniqueString(site.id)}'
    siteId: site.id
  }
}

resource cloudTargets 'Microsoft.Edge/targets@2026-05-01-preview' = [for (target, i) in targets: {
  name: target.name
  location: clusterLocations[targetIndices[i]]
  dependsOn: [
    siteReference
  ]
  properties: {
    capabilities: [
      capability
    ]
    contextId: contextId
    description: 'Cloud target for ARM template infrastructure deployment'
    displayName: 'Cloud Infrastructure Target'
    hierarchyLevel: hierarchy
  }
}]

resource dynamicConfigs 'Microsoft.Edge/configurations/dynamicConfigurations@2026-05-01-preview' = [for (target, i) in targets: {
  name: '${target.name}/${configTemplateUid}'
  dependsOn: [
    cloudTargets[i]
  ]
  properties: {
    currentVersion: '1'
  }
}]

resource configVersions 'Microsoft.Edge/configurations/dynamicConfigurations/versions@2026-05-01-preview' = [for (target, i) in targets: {
  parent: dynamicConfigs[i]
  name: '1.0.0'
  properties: {
    values: string(union(target.configuration, { clusterLocation: clusterLocations[targetIndices[i]] }))
  }
}]
