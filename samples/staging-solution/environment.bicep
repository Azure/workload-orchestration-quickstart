param location string

// ─── Context ───
resource context 'Microsoft.Edge/contexts@2026-03-01' = {
  name: 'ContosoContext'
  location: location
  properties: {
    capabilities: [
      {
        name: 'Quality'
        description: 'Quality capability'
      }
      {
        name: 'Manufacturing'
        description: 'Manufacturing capability'
      }
      {
        name: 'Retail'
        description: 'Retail capability'
      }
    ]
    hierarchies: [
      {
        name: 'Department'
        description: 'Department level hierarchy'
      }
      {
        name: 'Unit'
        description: 'Unit level hierarchy'
      }
    ]
  }
}

// ─── Site ───
resource site 'Microsoft.Edge/sites@2025-06-01' = {
  name: 'ContosoSite'
  properties: {
    displayName: 'ContosoSite'
    description: 'Contoso site'
    siteAddress: {
      streetAddress1: '1 Microsoft Way'
      city: 'Redmond'
      stateOrProvince: 'WA'
      country: 'US'
      postalCode: '98052'
    }
    labels: {
      level: 'Department'
    }
  }
}

// ─── Site Reference ───
resource siteReference 'Microsoft.Edge/contexts/siteReferences@2026-03-01' = {
  parent: context
  name: 'ContosoSiteReference'
  properties: {
    siteId: site.id
  }
}

output contextId string = context.id
