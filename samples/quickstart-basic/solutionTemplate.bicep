import { HelmChart } from '../../workload-orchestration/modules/solutionTemplate.bicep'

param location string

// ─── Schema ───
resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: 'QualityAppSchema'
  location: location
  properties: {}
}

resource schemaVersion 'Microsoft.Edge/schemas/versions@2026-03-01' = {
  parent: schema
  name: '1.0.0'
  properties: {
    value: '''
      rules:
        configs:
          ErrorThreshold:
            type: float
            required: true
            editableBy:
              - OT
    '''
  }
}

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
      schema:
        name: $${schema.name}
        version: $${schemaVersion.name}
      configs:
        AppName: QualityApp
        ErrorThreshold: 0.5
    '''
    specification: HelmChart('oci://ghcr.io/stefanprodan/charts/podinfo', '6.9.3') 
  }
}

output solutionTemplateId string = solutionTemplate.id
output solutionTemplateVersionId string = solutionTemplateVersion.id
