param location string = 'eastus'
param extensionPrincipalId string
 
// ─── Azure Container Registry ───────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'ContosoACR'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    dataEndpointEnabled: true
  }
}

// ─── Client Scope Map & Token (pull from connected registry) ────────────────────────
// Used by: workloads on the Arc cluster (kubelet / pods) to pull images from
// the local connected registry at the cluster IP (e.g. 10.0.12.0/<repo>:<tag>).
resource scopeMap 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-07-01' = {
  parent: acr
  name: 'all-repos-read'
  properties: {
    description: 'Client pull permissions for workloads consuming the connected registry'
    actions: [
      'repositories/*/content/read'
      'repositories/*/metadata/read'
    ]
  }
}

resource token 'Microsoft.ContainerRegistry/registries/tokens@2023-07-01' = {
  parent: acr
  name: 'all-repos-pull-token'
  properties: {
    scopeMapId: scopeMap.id
    status: 'enabled'
  }
}

// ─── Sync Scope Map & Token (parent ACR → connected registry replication) ──────────
// Used by: the connected registry daemon itself to sync content from its
// parent cloud ACR over the gateway channel. 
resource syncScopeMap 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-07-01' = {
  parent: acr
  name: 'ContosoConnectedRegistry'
  properties: {
    description: 'Sync scope map for connected registry (also extended per-solution by trigger-staging.sh)'
    actions: [
      'repositories/*/content/read'
      'repositories/*/metadata/read'
      'gateway/contosoconnectedregistry/config/read'
      'gateway/contosoconnectedregistry/config/write'
      'gateway/contosoconnectedregistry/message/read'
      'gateway/contosoconnectedregistry/message/write'
    ]
  }
}

resource syncToken 'Microsoft.ContainerRegistry/registries/tokens@2023-07-01' = {
  parent: acr
  name: 'ContosoConnectedRegistry'
  properties: {
    scopeMapId: syncScopeMap.id
    status: 'enabled'
  }
}

// ─── Connected Registry ──────────────────────────────────────────────────────
// Represents a local cache/mirror on the Arc cluster
resource connectedRegistry 'Microsoft.ContainerRegistry/registries/connectedRegistries@2025-04-01' = {
  parent: acr
  name: 'ContosoConnectedRegistry'
  properties: {
    mode: 'ReadOnly'
    parent: {
      syncProperties: {
        tokenId: syncToken.id
        messageTtl: 'P2D'
        schedule: '* * * * *'
      }
    }
    logging: {
      logLevel: 'Debug'
    }
    clientTokenIds: [
      token.id
    ]
  }
}

// ─── Role Assignment: Contributor ──────────────────────────────────────────
// Required for the workload-orchestration extension to manage resources
resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, extensionPrincipalId, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: extensionPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Role Assignment: Container Registry Contributor and Data Access ──────
// Required for the connected registry to sync images
resource acrContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, extensionPrincipalId, 'AcrContributorDataAccess')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3bc748fc-213d-45c1-8d91-9da5725539b9')
    principalId: extensionPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Role Assignment: AcrPull ──────────────────────────────────────────────
// Required for the extension to pull images from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, extensionPrincipalId, 'AcrPull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: extensionPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output acrName string = acr.name
output acrResourceId string = acr.id
output connectedRegistryName string = connectedRegistry.name
