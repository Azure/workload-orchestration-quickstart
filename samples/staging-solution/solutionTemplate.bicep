import { HelmChartWithStaging } from '../../workload-orchestration/modules/solutionTemplate.bicep'

param location string
param acrResourceId string
param imageName string = 'podinfo'
param imageTag string = 'latest'
param LocalConnectedRegistrySecretName string = 'my-acr-secret'
param namespace string = 'workloadorchestrationresources'
param repository string = 'oci://contosoacr.azurecr.io/charts/simple-chart'
param version string = '1.0.0'

// ─── Solution Template ───
resource solutionTemplate 'Microsoft.Edge/solutionTemplates@2026-03-01' = {
  name: 'QualityApp'
  location: location
  properties: {
    description: 'Quality application'
    capabilities: ['Quality', 'Retail']
  }
}

resource solutionTemplateVersion 'Microsoft.Edge/solutionTemplates/versions@2026-03-01' = {
  parent: solutionTemplate
  name: '1.0.0'
  properties: {
    configurations: $$'''
      configs:
        AppName: QualityApp
        fullnameOverride: qualityapp
        replicaCount: 2
        image:
          repository: ${{$connectedRegistryIP()}}+/$${imageName}
          tag: $${imageTag}
          pullPolicy: Always
          pullSecrets:
            name: $${LocalConnectedRegistrySecretName}
            namespace: $${namespace}
    '''
    specification:  HelmChartWithStaging(repository, version, acrResourceId, ['${imageName}:${imageTag}'])
  }
}

output solutionTemplateId string = solutionTemplate.id
output solutionTemplateVersionId string = solutionTemplateVersion.id
