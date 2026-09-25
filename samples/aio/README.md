# Quickstart: Deploy Azure IoT Operations

This folder contains an Azure IoT Operations (AIO) setup sample for an Arc-enabled Kubernetes cluster using Azure Workload Orchestration (`Microsoft.Edge`). Configure [`main.bicepparam`](./main.bicepparam) and follow the steps below; you do not need to edit the Bicep source to deploy the sample.

## What gets deployed

Deploying [`main.bicep`](./main.bicep) provisions the AIO infrastructure through Workload Orchestration's **Cloud Target → Solution Template → Solution Deployment** flow, with separate, ordered deployments for enablement and instance creation:

| Deployment | Purpose |
| --- | --- |
| **Enablement** | Prepares the Arc-connected cluster with the extensions required by AIO. |
| **Instance** | Creates the AIO Custom Location and instance on that cluster. |

## Prerequisites

- Fork or push this repository to GitHub or Azure DevOps.
- Complete the [Pipelines Setup](../../docs/pipelines.md).
- Connect a Kubernetes cluster to Azure Arc and enable the Custom Locations feature.
- A **storage account** with hierarchical namespace enabled:

  ```powershell
  az storage account create --name $STORAGE_ACCOUNT --location $LOCATION --resource-group $RESOURCE_GROUP --enable-hierarchical-namespace true
  ```

- A **schema registry** connected to the storage account:

  ```powershell
  az iot ops schema registry create --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP --registry-namespace $SCHEMA_REGISTRY_NAMESPACE --sa-resource-id $(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP -o tsv --query id)
  ```

- An **Azure Device Registry namespace**:

  ```powershell
  az iot ops ns create -n myqsnamespace -g $RESOURCE_GROUP
  ```

## Use the sample

1. Set `resourceGroup`, `templateFile`, and `parametersFile` in `workload-orchestration.yaml`:

   ```yaml
   resourceGroup: "<your-resource-group>"
   templateFile: "./samples/aio/main.bicep"
   parametersFile: "./samples/aio/main.bicepparam"
   ```

2. Fill in `main.bicepparam`: set `schemaRegistryId` and `adrNamespaceId`. Each entry in `targets` has three fields: `name` (the cloud target), `resourceGroupName` (the resource group containing the Arc cluster), and `configuration` (the existing Arc `clusterName`, desired `customLocationName`, and desired `aioInstanceName`). The deployment identity needs access to each target resource group.
3. Open a PR to run **WO Validate**, then merge to `main` to run **WO Sync Resources** and deploy AIO.
