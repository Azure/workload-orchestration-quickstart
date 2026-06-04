import { HelmChart } from '../../workload-orchestration/modules/solutionTemplate.bicep'

param location string

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
    '''
    specification: HelmChart('oci://ghcr.io/stefanprodan/charts/podinfo', '6.9.3') 
  }
}

output solutionTemplateId string = solutionTemplate.id
output solutionTemplateVersionId string = solutionTemplateVersion.id
