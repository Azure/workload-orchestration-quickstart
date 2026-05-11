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
module target 'target.bicep' = {
  name: 'Target'
  params: {
    location: location
    contextId: environment.outputs.contextId
  }
}

// ─── 3. Solution Template (includes Schema) ───
module solutionTemplate 'solutionTemplate.bicep' = {
  name: 'SolutionTemplate'
  params: {
    location: location
  }
}

// ─── Outputs ───
output contextId string = environment.outputs.contextId
output targetId string = target.outputs.targetId
output solutionTemplateId string = solutionTemplate.outputs.solutionTemplateId
output solutionTemplateVersionId string = solutionTemplate.outputs.solutionTemplateVersionId
