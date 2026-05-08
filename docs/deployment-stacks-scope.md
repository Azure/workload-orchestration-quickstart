## Resource Deployment Scope

By default, the workflows create the deployment stack at **resource group** level, targeting the resource group specified in `workload-orchestration.yaml`. All resources from the Bicep template (specified by `templateFile`) — including any imported modules — are deployed into this single resource group. The workflows use the [`azure/bicep-deploy@v2`](https://github.com/azure/bicep-deploy) action with `type: deploymentStack`.

You can change the scope depending on your requirements:

> **Note:** Deny settings (resource protection) only apply at the level of the deployment stack scope. For example, a resource-group-scoped stack only blocks changes to resources within that resource group. If you need protection across multiple resource groups or the entire subscription, use a higher scope accordingly.

| Scope | Bicep `targetScope` | `scope` in `bicep-deploy` action | `scope` on resources | Auth change |
|---|---|---|---|---|
| **Resource Group** (default) | *(none — default)* | `resourceGroup` | *(none needed — deploys directly)* | `subscription-id` in login |
| **Subscription** | `subscription` | `subscription` | `resourceGroup('<rg-name>')` | `subscription-id` in login |
| **Tenant** | `tenant` | `tenant` | `resourceGroup('<sub-id>', '<rg-name>')` | `allow-no-subscriptions: true` in login |
| **Management Group** | `managementGroup` | `managementGroup` | `resourceGroup('<sub-id>', '<rg-name>')` | `allow-no-subscriptions: true` in login |

To change scope, update:
1. `targetScope` in your Bicep template
2. Resource `scope` on each resource (add resource group, subscription ID as needed)
3. `scope:` in the `azure/bicep-deploy@v2` steps in all workflow files
4. For **subscription** scope: remove `resource-group-name` from workflow deploy steps (the resource group is set in the Bicep resource `scope` instead)
5. For **tenant** or **management group** scopes:
    - Add `management-group-id` to workflow deploy steps (for management group)
    - Change `azure/login` to use `allow-no-subscriptions: true` instead of `subscription-id`

### Examples by scope

#### Resource Group (default)

No `targetScope` needed. Resources deploy directly into the resource group from `workload-orchestration.yaml`. No workflow changes required.

**main.bicep:**
```bicep
// no targetScope (defaults to resourceGroup)

resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: '<your-schema-name>'
  location: '<location>'
  properties: {}
}
```

**Workflow step (default):**
```yaml
- uses: azure/bicep-deploy@v2
  with:
    type: deploymentStack
    operation: create
    scope: resourceGroup
    resource-group-name: ${{ steps.config.outputs.rg }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    template-file: ./workload-orchestration/main.bicep
    # ... other inputs
```

#### Subscription

**main.bicep:**
```bicep
targetScope = 'subscription'

resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: '<your-schema-name>'
  scope: resourceGroup('my-resource-group')
  location: '<location>'
  properties: {}
}
```

**Workflow step — change `scope` to `subscription`, remove `resource-group-name`:**
```yaml
- uses: azure/bicep-deploy@v2
  with:
    type: deploymentStack
    operation: create
    scope: subscription
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    template-file: ./workload-orchestration/main.bicep
    # ... other inputs (no resource-group-name)
```

#### Tenant

**main.bicep:**
```bicep
targetScope = 'tenant'

resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: '<your-schema-name>'
  scope: resourceGroup('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'my-resource-group')
  location: '<location>'
  properties: {}
}
```

**Workflow step — change `scope` to `tenant`, remove `resource-group-name` and `subscription-id`:**
```yaml
- uses: azure/bicep-deploy@v2
  with:
    type: deploymentStack
    operation: create
    scope: tenant
    template-file: ./workload-orchestration/main.bicep
    # ... other inputs (no resource-group-name or subscription-id)
```

**Azure login — add `allow-no-subscriptions`:**
```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    allow-no-subscriptions: true
```

#### Management Group

**main.bicep:**
```bicep
targetScope = 'managementGroup'

resource schema 'Microsoft.Edge/schemas@2026-03-01' = {
  name: '<your-schema-name>'
  scope: resourceGroup('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'my-resource-group')
  location: '<location>'
  properties: {}
}
```

**Workflow step — change `scope` to `managementGroup`, add `management-group-id`, remove `resource-group-name` and `subscription-id`:**
```yaml
- uses: azure/bicep-deploy@v2
  with:
    type: deploymentStack
    operation: create
    scope: managementGroup
    management-group-id: <your-management-group-id>
    template-file: ./workload-orchestration/main.bicep
    # ... other inputs (no resource-group-name or subscription-id)
```

**Azure login — add `allow-no-subscriptions`:**
```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    allow-no-subscriptions: true
```