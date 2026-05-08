# Workload Orchestration — Git-as-Source Jump Start

Manage Workload Orchestration resources (schemas, solution templates, config templates) as **Bicep templates in Git** with automated validation, deployment via Azure Deployment Stacks, and customizable resource protection settings.

## Contents

- [Repository Structure](#repository-structure)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Customize Resource Management](#customize-resource-management)
- [Included Modules](#included-modules)
- [Resource Deployment Scope](#resource-deployment-scope)

## Repository Structure

```
workload-orchestration.yaml   # Deployment stack settings (resource group, template path etc.)
workload-orchestration/
  main.bicep
  modules/
    solutionTemplate.bicep     # Reusable module with helper functions for solution template resources
.github/workflows/
  validate-bicep.yml           # PR gate: validate
  sync-bicep.yml               # Sync on merge to main (Deployment Stacks)
```

`workload-orchestration.yaml` is the central configuration file for the deployment. It specifies the target resource group, the Bicep template to deploy, deny settings, and resource lifecycle behavior. Here is the default configuration:

```yaml
resourceGroup: "<your-resource-group>"
templateFile: "./workload-orchestration/main.bicep"
denySettingsMode: none
denySettingsExcludedActions:
  - Microsoft.Edge/configTemplates/linkToHierarchies/action
  - Microsoft.Edge/configTemplates/unLinkFromHierarchies/action
actionOnUnmanageResources: detach
actionOnUnmanageResourceGroups: detach
```

See [Customize Resource Management](#customize-resource-management) for a full breakdown of each field.

The repo ships with a sample `main.bicep` as a starting point for declaring your Workload Orchestration resources (schemas, solution templates, config templates, and their versions). You can rename it, restructure it, or replace it entirely — just update the `templateFile` field in `workload-orchestration.yaml` to point to whichever Bicep template you want to use as the deployment entry point. All resources defined in that template — including any referenced modules — are deployed together.

The `modules/` folder includes optional reusable Bicep modules that simplify defining Workload Orchestration resources. See [Included Modules](#included-modules) for details.

## How It Works

1. **Edit** your Bicep templates in a feature branch — add, update, or remove resource declarations.
2. **Open a PR** to `main` — the validate workflow runs automatically:
   - Validates the Bicep templates against Azure.
   - Posts a validation result comment on the PR.
3. **Merge** to `main` — the sync workflow syncs resources to Azure via Deployment Stacks with deny settings.

## Prerequisites

### Azure Authentication

The workflows authenticate to Azure via **OpenID Connect (OIDC)** using a **user-assigned managed identity** with federated credentials. To set this up, follow the guide: [Connect GitHub Actions to Azure via OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect). You will need to create a managed identity, configure federated credentials for both the `main` branch and pull requests, and store the identity's `clientId`, `tenantId`, and `subscriptionId` as GitHub secrets.

Store the following as **GitHub repository secrets:**
- `AZURE_CLIENT_ID` — User-assigned managed identity client ID
- `AZURE_TENANT_ID` — Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` — Target subscription ID

> **Note:** OIDC with a user-assigned managed identity is the recommended approach, but other authentication methods are also supported (e.g., service principal with a secret or certificate). See [Use GitHub Actions to connect to Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=identity) for all available options.

#### Required Azure RBAC Roles

Assign one of the following roles to the managed identity. See [Deployment stacks](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks) for more details.

| Role | When to use |
|---|---|
| **Azure Deployment Stack Owner** | **Required** when `--deny-settings-mode` is `denyWriteAndDelete` or `denyDelete`. Can manage deployment stacks **including** creating and deleting deny assignments. |
| **Azure Deployment Stack Contributor** | Use when `--deny-settings-mode` is `none` (the default in this repo). Can manage deployment stacks but **cannot** create or delete deny assignments. |

## Getting Started

1. **Fork** this repo into your own GitHub account or organization.
2. **Set up Azure auth:** Follow the [Connect GitHub Actions to Azure via OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect) guide to configure OIDC authentication, then store `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` as repository secrets.
3. **Configure deployment settings** in `workload-orchestration.yaml` — see [Repository Structure](#repository-structure) and [Customize Resource Management](#customize-resource-management) for details.
4. **Author your resources** — define schemas, solution templates, config templates, and their versions in your Bicep templates. Set the `templateFile` field in `workload-orchestration.yaml` to point to your top-level template.
5. Push a branch, open a PR, and the validation workflow runs automatically.
6. Merge the PR to `main` — the sync workflow triggers and syncs your resources to Azure.

## Customize Resource Management

The deployment stack protects managed resources from out-of-band changes and controls their lifecycle. All settings are configured in `workload-orchestration.yaml`.

```yaml
resourceGroup: my-resource-group
templateFile: "./workload-orchestration/main.bicep"
denySettingsMode: none
denySettingsExcludedActions:
  - Microsoft.Edge/configTemplates/linkToHierarchies/action
  - Microsoft.Edge/configTemplates/unLinkFromHierarchies/action
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

The default value includes actions required for config template hierarchy operations. Git-based hierarchy linking is not yet supported, so these actions must be allowlisted to allow linking and unlinking config templates to hierarchies from outside the deployment stack (e.g., via CLI or portal):
```yaml
# Default
denySettingsExcludedActions:
  - Microsoft.Edge/configTemplates/linkToHierarchies/action
  - Microsoft.Edge/configTemplates/unLinkFromHierarchies/action
```

You can add more actions to the list as needed:

| Action | Why you might exclude it |
|---|---|
| `Microsoft.Edge/configTemplates/linkToHierarchies/action` | **(required)** Git-based linking not yet supported; must be performed outside the stack |
| `Microsoft.Edge/configTemplates/unLinkFromHierarchies/action` | **(required)** Git-based unlinking not yet supported; must be performed outside the stack |
| `Microsoft.Resources/tags/write` | Allow tagging resources without going through the stack |
| `Microsoft.Authorization/locks/write` | Allow adding resource locks directly |
| `Microsoft.Insights/diagnosticSettings/write` | Allow configuring diagnostics outside the stack |

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

## Included Modules

The `modules/` folder contains optional, reusable Bicep modules that provide helper functions for defining Workload Orchestration resources. You can use them, extend them, or remove them as needed.

### `solutionTemplate.bicep`

Exports a `HelmChart` function that builds the component structure for a Helm-based solution template. Pass in a chart repo URL and version, and it returns the correctly shaped specification object.

**Usage:**
```bicep
import { HelmChart } from 'modules/solutionTemplate.bicep'

resource solutionTemplateVersion 'Microsoft.Edge/solutionTemplates/versions@2026-03-01' = {
  parent: solutionTemplate
  name: '1.0.0'
  properties: {
    configurations: $$'''
      schema:
        name: $${schema.name}
        version: $${schemaVersion.name}
      configs:
        ErrorThreshold: ${{$val(ErrorThreshold)}}
    '''
    specification: HelmChart('<repo url>', '<version>')
  }
}
```

You can add more helper functions to this module or create new modules for schemas and config templates as your project grows.

## Resource Deployment Scope

By default, the workflows create the deployment stack at **resource group** level, targeting the resource group specified in `workload-orchestration.yaml`. All resources from the Bicep template (specified by `templateFile`) — including any imported modules — are deployed into this single resource group. The workflows use the [`azure/bicep-deploy@v2`](https://github.com/azure/bicep-deploy) action with `type: deploymentStack`.

If you wish to change the scope to Subscriptions or Management Group, take a look at [Resource Deployment Scope](docs/deployment-stacks-scope.md).
