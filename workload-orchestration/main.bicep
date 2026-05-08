import { HelmChart } from 'modules/solutionTemplate.bicep'

targetScope = 'resourceGroup'
var location = 'eastus2euap'

resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: 'Contoso-App-Schema'
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
              editableAt:
                - factory
              editableBy:
                - OT
    '''
  }
}

// ─── Solution Template ───
resource solutionTemplate 'Microsoft.Edge/solutionTemplates@2026-03-01' = {
  name: 'Contoso-App-Solution-Template'
  dependsOn: [schema]
  location: location
  properties: {
    description: 'Contoso App Solution Template'
    capabilities: [
      'shubpatil-soap'
    ]
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
        ErrorThreshold: ${{$val(ErrorThreshold)}}
    '''
    specification: HelmChart('ghcr.io/eclipse-symphony/tests/helm/simple-chart', '0.3.0')
  }
}

// ─── Config Template ───
resource configTemplate 'Microsoft.Edge/configTemplates@2026-03-01' = {
  name: 'Contoso-App-Config-Template'
  dependsOn: [schema]
  location: location
  properties: {
    description: 'Contoso App config template'
  }
}

resource configTemplateVersion 'Microsoft.Edge/configTemplates/versions@2026-03-01' = {
  parent: configTemplate
  name: '1.0.0'
  properties: {
    configurations: $$'''
      schema:
        name: $${schema.name}
        version: $${schemaVersion.name}
      configs:
        AppName: ContosoApp
        ErrorThreshold: ${{$val(ErrorThreshold)}}
    '''
  }
}

// Outputs
output schemaName string = schema.name
output schemaVersionName string = schemaVersion.name
output solutionTemplateName string = solutionTemplate.name
output solutionTemplateVersionName string = solutionTemplateVersion.name
output configTemplateName string = configTemplate.name
output configTemplateVersionName string = configTemplateVersion.name
