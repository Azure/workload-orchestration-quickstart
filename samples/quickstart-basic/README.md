# Quickstart: Create a Basic Solution

This sample sets up a complete Workload Orchestration environment — site, context, site reference, target, schema, and solution template — with proper dependencies.

## Prerequisites

- An **Arc-connected Kubernetes cluster** with the Workload Orchestration extension installed and a **Custom Location** configured.

## Steps

### 1. Fork the repo

Fork this repo into your own GitHub account or organization.

### 2. Set up Azure authentication

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

### 3. Author your resources

1. Copy the sample files into `workload-orchestration/`:

   ```bash
   cp -r samples/quickstart-basic/* workload-orchestration/
   ```

2. Replace `<CUSTOM_LOCATION_ID>` in `target.bicep` with your Custom Location ARM resource ID.

3. Set your resource group name in `workload-orchestration.yaml`.

### 4. Validate and sync

1. Push a branch, open a PR — the validation workflow runs automatically.
2. Merge the PR to `main` — the sync workflow deploys your resource definitions to Azure via Deployment Stacks.

### 5. Deploy to your cluster (manual step)

Go to **Actions → Deploy by Name** and manually trigger the workflow to deploy your solution to the cluster.

> [!IMPORTANT]
> Merging to `main` only syncs resource definitions to Azure. To **deploy your application to a cluster**, you must manually trigger the **Deploy by Name** workflow from the GitHub Actions UI.
