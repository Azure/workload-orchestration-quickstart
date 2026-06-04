## Resource Deployment Scope

By default, the workflows create the deployment stack at **resource group** level, targeting the resource group specified in `workload-orchestration.yaml`. All resources from the Bicep template (specified by `templateFile`) — including any imported modules — are deployed into this single resource group. 

You can change the scope depending on your requirements:

> **Note:** Deny settings (resource protection) only apply at the level of the deployment stack scope. For example, a resource-group-scoped stack only blocks changes to resources within that resource group. If you need protection across multiple resource groups or the entire subscription, use a higher scope accordingly.

| Scope | Bicep `targetScope` | `scope` in `bicep-deploy` action (GitHub) | Azure CLI command (ADO) | `scope` on resources | Auth change |
|---|---|---|---|---|---|
| **Resource Group** (default) | *(none — default)* | `resourceGroup` | `az stack group create` | *(none needed — deploys directly)* | `subscription-id` in GitHub login; default subscription scope in ADO service connection |
| **Subscription** | `subscription` | `subscription` | `az stack sub create` | `resourceGroup('<rg-name>')` | `subscription-id` in GitHub login; subscription-scoped service connection in ADO |
| **Management Group** | `managementGroup` | `managementGroup` | `az stack mg create` | `resourceGroup('<sub-id>', '<rg-name>')` | `allow-no-subscriptions: true` in GitHub login; management-group-scoped service connection in ADO |

> **Note:** Deployment stacks are not supported at **tenant** scope. If you need tenant-scoped deployments, use a plain deployment (`az deployment tenant create` or `azure/bicep-deploy@v2` with `type: deployment`) instead — you lose stack features (deny settings, lifecycle management).

To change scope, update:
1. `targetScope` in your Bicep template
2. Resource `scope` on each resource (add resource group, subscription ID as needed)
3. **GitHub Actions** — update `scope:` in the `azure/bicep-deploy@v2` steps in all workflow files under `.github/workflows/`
4. **Azure DevOps** — update the `az stack ...` command in the `AzureCLI@2` tasks in all pipeline files under `.pipelines/`
5. For **subscription** scope:
    - GitHub: remove `resource-group-name` from workflow deploy steps (the resource group is set in the Bicep resource `scope` instead)
    - ADO: switch from `az stack group create` to `az stack sub create` and remove `--resource-group`; add `--location <region>`
6. For **management group** scope:
    - GitHub: add `management-group-id` to workflow deploy steps; change `azure/login` to use `allow-no-subscriptions: true` instead of `subscription-id`
    - ADO: switch to `az stack mg create` with `--management-group-id` and `--location`; the service connection must be scoped to a management group.

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

**GitHub Actions step (default):**
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

**Azure DevOps task (default):**
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureServiceConnection)
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az stack group create \
        --name workload-orchestration-stack \
        --resource-group "$(config.rg)" \
        --template-file "$(config.templateFile)" \
        --action-on-unmanage detachAll \
        --deny-settings-mode none \
        --yes
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

**GitHub Actions step — change `scope` to `subscription`, remove `resource-group-name`:**
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

**Azure DevOps task — switch to `az stack sub create`, remove `--resource-group`, add `--location` (region where the stack resource itself is stored — not where your deployed resources live):**
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureServiceConnection)
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az stack sub create \
        --name workload-orchestration-stack \
        --location eastus \
        --template-file "$(config.templateFile)" \
        --action-on-unmanage detachAll \
        --deny-settings-mode none \
        --yes
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

**GitHub Actions step — change `scope` to `managementGroup`, add `management-group-id`, remove `resource-group-name` and `subscription-id`:**
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

**GitHub Azure login — add `allow-no-subscriptions`:**
```yaml
- uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    allow-no-subscriptions: true
```

**Azure DevOps task — switch to `az stack mg create` with `--management-group-id` and `--location` (region where the stack resource itself is stored — not where your deployed resources live):**
```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: $(azureServiceConnection)   # must be management-group-scoped
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az stack mg create \
        --name workload-orchestration-stack \
        --management-group-id <your-management-group-id> \
        --location eastus \
        --template-file "$(config.templateFile)" \
        --action-on-unmanage detachAll \
        --deny-settings-mode none \
        --yes
```

> **Note:** For management group scope in ADO, the Azure Resource Manager service connection must be created at the management group scope. See [Service connection scope levels](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints#scope-levels) for details.