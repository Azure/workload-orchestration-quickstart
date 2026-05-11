# Quickstart: Create a Basic Solution

This sample sets up Workload Orchestration and creates a basic solution — including site, context, site reference, target, schema, and solution template — with proper dependencies.

## Usage

1. Copy all files from this folder into the `workload-orchestration/` folder at the root of the repo:

   ```bash
   cp -r samples/quickstart-basic/* workload-orchestration/
   ```

2. Replace `<CUSTOM_LOCATION_ID>` in `target.bicep` with the ARM resource ID of your Custom Location associated with your Arc-connected cluster.
3. Update `workload-orchestration.yaml` with your resource group name.
4. Push a branch, open a PR, and merge to `main` — this syncs your resources to Azure.
5. Go to **Actions → Deploy by Name** and manually trigger the workflow to deploy your solution to a target cluster.

> [!IMPORTANT]
> Merging to `main` only syncs resource definitions to Azure. To **deploy your application to a cluster**, you must manually trigger the **Deploy by Name** workflow from the GitHub Actions UI.
