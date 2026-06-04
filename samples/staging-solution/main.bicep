targetScope = 'resourceGroup'

var location = 'eastus'

// ─── 1. Environment (Site + Context + Site Reference) ───
module environment 'environment.bicep' = {
  name: 'Environment'
  params: {
    location: location
  }
}

// ─── 2. Target ───
module targets 'target.bicep' = {
  name: 'Targets'
  params: {
    location: location
    contextId: environment.outputs.contextId
    devtargetcustomlocationId: '<DEV_TARGET_CUSTOM_LOCATION_ID>'
    testtargetcustomlocationId: '<TEST_TARGET_CUSTOM_LOCATION_ID>'
  }
}

// ─── 3. Solution Template (includes Schema) ───
module solutionTemplate 'solutionTemplate.bicep' = {
  name: 'SolutionTemplate'
  params: {
    location: location
    acrResourceId: '<ACR_RESOURCE_ID>'
    LocalConnectedRegistryIP: '<LOCAL_CONNECTED_REGISTRY_IP>'
  }
}

// ─── Outputs ───
output contextId string = environment.outputs.contextId
output devTargetId string = targets.outputs.devtargetId
output testTargetId string = targets.outputs.testtargetId
output solutionTemplateId string = solutionTemplate.outputs.solutionTemplateId
output solutionTemplateVersionId string = solutionTemplate.outputs.solutionTemplateVersionId
