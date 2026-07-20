# Customize Resource Management

The deployment stack protects managed resources from out-of-band changes and controls their lifecycle. All settings are configured in `workload-orchestration.yaml`.

```yaml
resourceGroup: my-resource-group
templateFile: "./workload-orchestration/main.bicep"
denySettingsMode: none
denySettingsExcludedActions: []
actionOnUnmanageResources: detach
actionOnUnmanageResourceGroups: detach
```

---

### `resourceGroup`

The target Azure resource group for deployment. **Required.**

---

### `templateFile`

The path to the Bicep template file to deploy. **Default:** `./workload-orchestration/main.bicep`.

---

### `denySettingsMode`

Controls whether Azure blocks direct (out-of-band) changes to resources managed by the stack.

| Value | Behavior |
|---|---|
| `denyWriteAndDelete` | Blocks both modifications and deletions of managed resources outside the stack. |
| `denyDelete` | Blocks deletions but allows modifications. Useful if you want to allow operational changes (e.g., scaling) while preventing accidental deletes. |
| `none` | **Default.** No restrictions. Resources can be freely modified or deleted outside the stack. |

---

### `denySettingsExcludedActions`

A list of Azure RBAC actions that are **exempt** from the deny assignment. These actions can be performed on managed resources even when deny settings are active.

> **Note:** This only has an effect when `denySettingsMode` is `denyWriteAndDelete` or `denyDelete`. With the default `none`, no deny assignment is created, so this list is ignored.

You can add more actions to the list as needed:

| Action | Why you might exclude it |
|---|---|
| `Microsoft.Resources/tags/write` | Allow tagging resources without going through the stack |
| `Microsoft.Authorization/locks/write` | Allow adding resource locks directly |
| `Microsoft.Insights/diagnosticSettings/write` | Allow configuring diagnostics outside the stack |

For example, to protect resources while still allowing tags, locks, and diagnostic settings to be changed out-of-band:

```yaml
denySettingsMode: denyWriteAndDelete
denySettingsExcludedActions:
  - Microsoft.Resources/tags/write
  - Microsoft.Authorization/locks/write
  - Microsoft.Insights/diagnosticSettings/write
```

---

### `actionOnUnmanageResources`

Controls what happens to **resources** when they are removed from the Bicep template and the stack is redeployed.

| Value | Behavior |
|---|---|
| `detach` | **Default.** Resources remain in Azure but are no longer tracked by the stack. |
| `delete` | Resources are **deleted** from Azure. |

---

### `actionOnUnmanageResourceGroups`

Controls what happens to **resource groups** when they are removed from the template.

| Value | Behavior |
|---|---|
| `detach` | **Default.** Resource groups remain in Azure but are no longer tracked. |
| `delete` | Resource groups are **deleted** from Azure. |

## Customize Resource Deployment Scope

By default, the workflows create the deployment stack at **resource group** level, targeting the resource group specified in `workload-orchestration.yaml`. All resources from the Bicep template (specified by `templateFile`) — including any imported modules — are deployed into this single resource group. 

If you wish to change the scope to Subscriptions or Management Group, take a look at [Resource Deployment Scope](deployment-stacks-scope.md).
