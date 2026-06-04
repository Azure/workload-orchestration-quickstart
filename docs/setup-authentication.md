# Authentication Setup

## Set up Azure authentication for GitHub Actions

1. **Create a user-assigned managed identity** in your Azure subscription.
2. **Add federated identity credentials (FIC)** for both:
    - The `main` branch
    - Pull requests

3. **Assign roles** to the managed identity on the target resource group:
    - **Azure Deployment Stack Contributor** (or **Owner** if using deny settings) — for managing the deployment stack.
    - **Contributor** — for creating and managing Workload Orchestration resources.

4. **Store the following as GitHub repository secrets:**
    - `AZURE_CLIENT_ID` — Managed identity client ID
    - `AZURE_TENANT_ID` — Azure AD tenant ID
    - `AZURE_SUBSCRIPTION_ID` — Target subscription ID

> For detailed auth setup instructions, see [Connect GitHub Actions to Azure via OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

## Set up Azure authentication for Azure DevOps Pipelines
1. In your Azure DevOps project, create an **Azure Resource Manager** service connection of type **App registration (automatic)** scoped to your target subscription/resource group. This auto-creates an Azure AD app registration.
2. Assign roles to the auto-created service principal on the target resource group:
   - **Azure Deployment Stack Contributor** (or **Owner** if using deny settings)
   - **Contributor**
3. Add the service connection name as a pipeline variable:
   - `azureServiceConnection` (the name of the service connection created above)

> For detailed auth setup instructions, see [Create an Azure Resource Manager service connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops).

## Required Azure RBAC Roles

The following roles are required for **managing the deployment stack**. Assign one of these to the managed identity. See [Deployment stacks](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks) for more details.

| Role | When to use |
|---|---|
| **Azure Deployment Stack Owner** | **Required** when `--deny-settings-mode` is `denyWriteAndDelete` or `denyDelete`. Can manage deployment stacks **including** creating and deleting deny assignments. |
| **Azure Deployment Stack Contributor** | Use when `--deny-settings-mode` is `none` (the default in this repo). Can manage deployment stacks but **cannot** create or delete deny assignments. |

> **Note:** In addition to the deployment stack role, the managed identity also needs sufficient permissions to **create and manage the Workload Orchestration resources** (e.g., sites, contexts, targets, schemas, solution templates) being deployed by the stack. Ensure the identity has the appropriate role (such as Contributor) on the target resource group.
