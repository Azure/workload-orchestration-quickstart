import { HelmTarget } from 'modules/target.bicep'

param location string
param contextId string

resource target 'Microsoft.Edge/targets@2026-03-01' = {
  name: 'ContosoTarget'
  location: location
  extendedLocation: {
    name: '<CUSTOM_LOCATION_ID>' // ARM resource ID of your Custom Location associated with your Arc-connected cluster
    type: 'CustomLocation'
  }
  properties: {
    capabilities: ['Quality', 'Manufacturing', 'Retail'] 
    contextId: contextId
    description: 'Contoso target'
    displayName: 'ContosoTarget'
    hierarchyLevel: 'Unit' 
    targetSpecification: HelmTarget()
  }
}

output targetId string = target.id
