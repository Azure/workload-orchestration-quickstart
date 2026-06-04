import { HelmTarget } from '../../workload-orchestration/modules/target.bicep'

param location string
param contextId string
param devtargetcustomlocationId string
param testtargetcustomlocationId string

resource devtarget 'Microsoft.Edge/targets@2026-03-01' = {
  name: 'ContosoDevTarget'
  location: location
  extendedLocation: {
    name: devtargetcustomlocationId // ARM resource ID of your Custom Location associated with your Arc-connected cluster
    type: 'CustomLocation'
  }
  properties: {
    capabilities: ['Quality', 'Manufacturing', 'Retail'] 
    contextId: contextId
    description: 'Contoso Dev Target'
    displayName: 'ContosoDevTarget'
    hierarchyLevel: 'Unit' 
    targetSpecification: HelmTarget()
  }
}

resource testtarget 'Microsoft.Edge/targets@2026-03-01' = {
  name: 'ContosoTestTarget'
  location: location
  extendedLocation: {
    name: testtargetcustomlocationId // ARM resource ID of your Custom Location associated with your Arc-connected cluster
    type: 'CustomLocation'
  }
  properties: {
    capabilities: ['Quality', 'Manufacturing', 'Retail'] 
    contextId: contextId
    description: 'Contoso Test Target'
    displayName: 'ContosoTestTarget'
    hierarchyLevel: 'Unit' 
    targetSpecification: HelmTarget()
  }
}


output devtargetId string = devtarget.id
output testtargetId string = testtarget.id
