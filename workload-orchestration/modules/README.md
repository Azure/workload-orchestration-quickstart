# Included Modules

The `modules/` folder contains optional, reusable Bicep modules that provide helper functions for defining Workload Orchestration resources. You can add more helper functions to these modules or create new modules as your project grows.

## `solutionTemplate.bicep`

### `HelmChart`

Exports a `HelmChart` function that builds the component structure for a Helm-based solution template. Pass in a chart repo URL and version, and it returns the correctly shaped specification object.

**Usage:**
```bicep
import { HelmChart } from 'modules/solutionTemplate.bicep'

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
    specification: HelmChart('<helm url>', '<version>')
  }
}
```

### `HelmChartWithStaging`

Exports a `HelmChartWithStaging` function that extends `HelmChart` with image staging support. Pass in a chart repo URL, version, an Azure Container Registry (ACR) resource ID, and an array of images to stage, and it returns the specification object with staged image configuration.

**Usage:**
```bicep
import { HelmChartWithStaging } from 'modules/solutionTemplate.bicep'

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
    specification: HelmChartWithStaging('<helm url>', '<version>', '<acr resource id>', [
      '<image1>'
      '<image2>'
    ])
  }
}
```

## `target.bicep`

### `HelmTarget`

Exports a `HelmTarget` function that builds the target specification for a Helm-based deployment target. Returns the correctly shaped topology and binding configuration.

**Usage:**
```bicep
import { HelmTarget } from 'modules/target.bicep'

resource target 'Microsoft.Edge/targets@2026-03-01' = {
  name: 'my-target'
  location: location
  extendedLocation: {
    name: '<CUSTOM_LOCATION_ID>'
    type: 'CustomLocation'
  }
  properties: {
    targetSpecification: HelmTarget()
  }
}
```
