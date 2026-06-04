# Quickstart: Create a Staging-Based Solution

This sample sets up a complete Workload Orchestration environment to stage your solution on cluster and deploy.

## What this sample does

It deploys a Helm-packaged workload to an Arc-connected cluster **without pulling images directly**. Instead, images are staged through an Azure Container Registry (ACR) and replicated to an on-cluster **connected registry**; workloads pull from that local registry over the cluster network.

End-to-end flow:

1. The staging infrastructure ([`infra.bicep`](./infra.bicep)) provisions an ACR plus a connected registry extension running on the cluster. The container image and Helm chart are pushed to ACR and synced down to the connected registry.
2. The solution template ([`solutionTemplate.bicep`](./solutionTemplate.bicep)) declares the Helm chart (pulled from ACR via `HelmChartWithStaging`) and the runtime config — most importantly, the image reference points at the **local connected registry IP**, so pods pull from the on-cluster mirror.
3. The targets ([`target.bicep`](./target.bicep)) — `ContosoDevTarget` and `ContosoTestTarget` — bind to two Custom Locations, letting you promote the same solution from dev → test on the same or different clusters.

### Config keys and how they reach the app

The `configurations` block in `solutionTemplate.bicep` is rendered into Helm values at deploy time. Values prefixed with `$${...}` are substituted from bicep parameters:

```yaml
configs:
  AppName: QualityApp
  fullnameOverride: qualityapp
  image:
    repository: $${LocalConnectedRegistryIP}/$${imageName}   # e.g. 10.0.0.42/podinfo
    tag: $${imageTag}                                        # e.g. latest
    pullPolicy: Always
    pullSecrets:
      name: $${LocalConnectedRegistrySecretName}             # docker-registry secret in the CL namespace
      namespace: $${namespace}                               # Custom Location namespace where the secret lives
```

To add or change configuration, edit the `configurations` block. Anything you put under `configs:` becomes a chart value at deploy time.

### The `simple-chart` Helm chart

The Helm chart this sample uses lives in [`charts/simple-chart`](../../charts/simple-chart) — it's a minimal generic chart that deploys whatever image you point it at:

- **[`deployment.yaml`](../../charts/simple-chart/templates/deployment.yaml)** — single `Deployment` with `replicaCount` pods running `image.repository:image.tag` on `containerPort` (default `9898`), with a non-root security context. If `image.pullSecrets.name` and `namespace` are both set, it attaches that secret as an `imagePullSecret` on the pod spec.
- **[`image-pull-secret.yaml`](../../charts/simple-chart/templates/image-pull-secret.yaml)** — cross-namespace secret copier. At install time it looks up the docker-registry secret you created in the Custom Location namespace (`pullSecrets.namespace`) and **copies it into the release namespace** so the pod can use it. If the secret doesn't exist in either namespace, the install fails fast with a clear message.

This is what lets the solution template's `image.repository: $${LocalConnectedRegistryIP}/$${imageName}` line work end-to-end: the chart pulls from the connected registry IP using credentials that were originally created once in the Custom Location namespace.

## Prerequisites
- Fork / Push this repository into GitHub or Azure DevOps.
- Complete the [Pipelines Setup](../../docs/pipelines.md).
- An **Arc-connected Kubernetes cluster** with the Workload Orchestration extension installed and a **Custom Location** configured.

## Part 1: Staging Infrastructure Setup
Staging requires an Azure Container Registry, with configuration to sync to a Connected Registry on the Edge. An `infra.bicep` is available to deploy this to Azure trivially:
- Azure Container Registry
- Client scope map and token (workload image pulls)
- Sync scope map and token (connected registry replication)
- Connected Registry (ReadOnly mode)
- Role assignments for the Workload Orchestration extension on your Kubernetes Cluster:
    - Contributor
    - Container Registry Contributor and Data Access
    - AcrPull

Follow [Staging Infrastructure Setup](staging-infra-setup.md) to prepare a Container Registry for Staging using `infra.bicep`

Alternatively, [How to stage a workload (Azure Arc Workload Orchestration)](https://learn.microsoft.com/en-us/azure/azure-arc/workload-orchestration/how-to-stage?tabs=bash) on Microsoft Learn covers this in more detail.

## Part 2: Sample

### 1. Point the deployment to this sample

Update `templateFile` in `workload-orchestration.yaml`:

```yaml
templateFile: "./samples/staging-solution/main.bicep"
```

### 2. Configure sample values

The staging infrastructure setup produces all the values you need. Fill them into `main.bicep` — it passes them down to `target.bicep` and `solutionTemplate.bicep` automatically.

| `main.bicep` parameter | Value | Where to get it |
| --- | --- | --- |
| `devtargetcustomlocationId` | ARM resource ID of the Custom Location for your **dev** target | From your Arc cluster setup |
| `testtargetcustomlocationId` | ARM resource ID of the Custom Location for your **test** target | From your Arc cluster setup |
| `acrResourceId` | ARM resource ID of the staging ACR | [`infra.bicep` deployment output](./staging-infra-setup.md#2-deploy-infrabicep) (`acrResourceId`) |
| `imageName` | Name of the image you pushed to the ACR (default: `podinfo`) | [Step 4](./staging-infra-setup.md#4-push-your-container-image-to-the-acr) (`IMAGE_NAME`) |
| `imageTag` | Tag of the image you pushed (default: `latest`) | [Step 4](./staging-infra-setup.md#4-push-your-container-image-to-the-acr) (`IMAGE_TAG`) |
| `repository` | Full OCI URL of the Helm chart inside the ACR, in the form `oci://<acr-login-server>/<chart-repo>/<chart-name>` (default: `oci://contosoacr.azurecr.io/charts/simple-chart`) | [Step 5](./staging-infra-setup.md#5-package-and-push-the-helm-chart-to-the-acr) (`CHART_REPO` + chart name) |
| `version` | Helm chart version you pushed (default: `1.0.0`) | [Step 5](./staging-infra-setup.md#5-package-and-push-the-helm-chart-to-the-acr) (`CHART_VERSION`) |
| `LocalConnectedRegistryIP` | Cluster IP assigned to the connected registry service | [Step 6](./staging-infra-setup.md#6-install-the-connected-registry-extension-on-the-arc-cluster) (`AVAILABLE_IP`) |
| `LocalConnectedRegistrySecretName` | Name of the image-pull secret on the cluster | [Step 7](./staging-infra-setup.md#7-make-the-image-pull-credentials-available-to-your-workloads) (`PULL_SECRET_NAME`, e.g. `my-acr-secret`) |
| `namespace` | Custom Location namespace where the secret lives (default: `workloadorchestration`) | [Step 7](./staging-infra-setup.md#7-make-the-image-pull-credentials-available-to-your-workloads) (`CL_NAMESPACE`) |

#### Override defaults with your own values

Parameters with defaults (`imageName`, `imageTag`, `repository`, `version`, `LocalConnectedRegistrySecretName`, `namespace`) are defined in `solutionTemplate.bicep` and don't need to be set unless you want to change them. To override one, pass it explicitly from `main.bicep`:

```bicep
module solutionTemplate 'solutionTemplate.bicep' = {
  name: 'SolutionTemplate'
  params: {
    location: location
    acrResourceId: '<ACR_RESOURCE_ID>'
    LocalConnectedRegistryIP: '<LOCAL_CONNECTED_REGISTRY_IP>'
    // Overrides — only include the ones you want to change
    imageName: 'myapp'
    imageTag: 'v1.2.3'
    repository: 'oci://myacr.azurecr.io/charts/myapp'
    version: '2.0.0'
    LocalConnectedRegistrySecretName: 'my-pull-secret'
    namespace: 'my-namespace'
  }
}
```

### 3. Validate and sync

1. Push a branch and open a PR to run validation.
2. Merge to `main` to sync resource definitions through deployment stacks.

### 4. Deploy to your cluster (manual step)

Manually trigger the **Deploy by Name** workflow to deploy your solution to the cluster.

> [!IMPORTANT]
> Merging to `main` only syncs resource definitions to Azure. To **deploy your application to a cluster**, you must manually trigger the **Deploy by Name** workflow from GitHub / Azure DevOps.

> [!NOTE]
> The **Deploy by Name** workflow stages the image to the cluster and deploys it in a single step. If you want to **stage now and deploy later** (for example, pre-stage during a maintenance window and roll out separately), run the staging and deployment commands manually via the Azure CLI — see [Publish and install solution](https://learn.microsoft.com/en-us/azure/azure-arc/workload-orchestration/how-to-stage?tabs=bash#publish-and-install-the-solution).
