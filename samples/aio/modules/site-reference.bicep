targetScope = 'resourceGroup'

param contextName string
param referenceName string
param siteId string

resource context 'Microsoft.Edge/contexts@2026-03-01' existing = {
  name: contextName
}

@onlyIfNotExists()
resource siteReference 'Microsoft.Edge/contexts/siteReferences@2026-03-01' = {
  parent: context
  name: referenceName
  properties: {
    siteId: siteId
  }
}
