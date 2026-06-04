# Staging Infrastructure Setup (infra.bicep)

This guide is a streamlined alternative to the [Learn portal staging setup](https://learn.microsoft.com/en-us/azure/azure-arc/workload-orchestration/how-to-stage). It uses [`infra.bicep`](./infra.bicep) to provision resources needed to stage images on your Arc-connected cluster in a single deployment.

## What it provisions
- Azure Container Registry (Premium)
- Client scope map and token (workload image pulls)
- Sync scope map and token (connected registry replication)
- Connected Registry (ReadOnly mode)
- Role assignments for the Workload Orchestration extension:
  - Contributor
  - Container Registry Contributor and Data Access
  - AcrPull

## Prerequisites
- An Arc-connected Kubernetes cluster with the Workload Orchestration extension installed and a Custom Location configured.
- A resource group for the staging infrastructure.

## Steps

### 1. Get the Workload Orchestration extension principal ID

#### Bash

```bash
EXTENSION_PRINCIPAL_ID=$(az k8s-extension show \
  --cluster-name "<ARC_CLUSTER_NAME>" \
  --resource-group "<ARC_CLUSTER_RESOURCE_GROUP>" \
  --cluster-type connectedClusters \
  --name workload-orchestration \
  --query "identity.principalId" -o tsv)
```

#### PowerShell

```powershell
$ExtensionPrincipalId = az k8s-extension show `
  --cluster-name "<ARC_CLUSTER_NAME>" `
  --resource-group "<ARC_CLUSTER_RESOURCE_GROUP>" `
  --cluster-type connectedClusters `
  --name workload-orchestration `
  --query "identity.principalId" -o tsv
```

### 2. Deploy `infra.bicep`

Run from the repo root.

#### Bash

```bash
az deployment group create \
  --resource-group "<RESOURCE_GROUP>" \
  --template-file ./samples/staging-solution/infra.bicep \
  --parameters extensionPrincipalId="$EXTENSION_PRINCIPAL_ID"
```

#### PowerShell

```powershell
az deployment group create `
  --resource-group "<RESOURCE_GROUP>" `
  --template-file ./samples/staging-solution/infra.bicep `
  --parameters extensionPrincipalId="$ExtensionPrincipalId"
```

After the deployment completes, the ACR resource ID and connected registry name are available in the deployment outputs and can be plugged into `main.bicep`.

### 3. Log in to the ACR

#### Bash

```bash
ACR_NAME="ContosoACR"
az acr login --name "$ACR_NAME"
```

#### PowerShell

```powershell
$AcrName = "ContosoACR"
az acr login --name $AcrName
```

### 4. Push your container image to the ACR

You have two options.

**Option A — Import directly into the ACR (no local Docker needed):**

#### Bash

```bash
IMAGE_NAME="podinfo" 
IMAGE_TAG="latest"
SOURCE_IMAGE="ghcr.io/stefanprodan/podinfo:6.9.3"   # e.g. ghcr.io/stefanprodan/podinfo:6.9.3

az acr import \
  --name "$ACR_NAME" \
  --source "$SOURCE_IMAGE" \
  --image "$IMAGE_NAME:$IMAGE_TAG"
```

#### PowerShell

```powershell
$ImageName   = "podinfo"
$ImageTag    = "latest"
$SourceImage = "ghcr.io/stefanprodan/podinfo:6.9.3"   # e.g. ghcr.io/stefanprodan/podinfo:6.9.3

az acr import `
  --name $AcrName `
  --source $SourceImage `
  --image "${ImageName}:${ImageTag}"
```

**Option B — Tag and push from your local machine (requires Docker):**

#### Bash

```bash
docker pull "$SOURCE_IMAGE"
docker tag  "$SOURCE_IMAGE" "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"
docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"
```

#### PowerShell

```powershell
docker pull $SourceImage
docker tag  $SourceImage "$AcrName.azurecr.io/${ImageName}:${ImageTag}"
docker push "$AcrName.azurecr.io/${ImageName}:${ImageTag}"
```

### 5. Package and push the Helm chart to the ACR

The sample chart lives in [`charts/simple-chart`](../../charts/simple-chart). Package it and push as an OCI artifact:

#### Bash

```bash
CHART_DIR="./charts/simple-chart"
CHART_REPO="charts"     # repository path inside the ACR, e.g. charts
CHART_VERSION="1.0.0"     # must match Chart.yaml version, e.g. 1.0.0
CHART_PACKAGE="simple-chart-$CHART_VERSION.tgz"     # the .tgz produced by helm package

# Authenticate Helm to the ACR using an AAD access token
ACR_TOKEN=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken)
echo "$ACR_TOKEN" | helm registry login "$ACR_NAME.azurecr.io" \
  --username 00000000-0000-0000-0000-000000000000 \
  --password-stdin

helm package "$CHART_DIR" --version "$CHART_VERSION"
helm push "$CHART_PACKAGE" "oci://$ACR_NAME.azurecr.io/$CHART_REPO"
```

#### PowerShell

```powershell
$ChartDir     = "./charts/simple-chart"
$ChartRepo    = "charts"     # repository path inside the ACR, e.g. charts
$ChartVersion = "1.0.0"        # must match Chart.yaml version, e.g. 1.0.0
$ChartPackage = "simple-chart-$ChartVersion.tgz"        # the .tgz produced by helm package

# Authenticate Helm to the ACR using an AAD access token
$AcrToken = az acr login --name $AcrName --expose-token --output tsv --query accessToken
$AcrToken | helm registry login "$AcrName.azurecr.io" `
  --username 00000000-0000-0000-0000-000000000000 `
  --password-stdin

helm package $ChartDir --version $ChartVersion
helm push $ChartPackage "oci://$AcrName.azurecr.io/$ChartRepo"
```

> The value to plug into `main.bicep` as `repository` is the full OCI URL including the chart name: `oci://<ACR_NAME>.azurecr.io/<CHART_REPO>/simple-chart` (e.g. `oci://contosoacr.azurecr.io/charts/simple-chart`).

> The sync scope map deployed by `infra.bicep` already grants `repositories/*/content/read` and `repositories/*/metadata/read`, so the connected registry will replicate the new image and chart automatically — no scope-map update needed.

### 6. Install the connected registry extension on the Arc cluster

The connected registry runs as an extension on your Arc-connected cluster. Pick a free IP from the cluster's service CIDR, generate a connection string from the ACR, and install the extension.

#### Bash

```bash
# 1. Check IPs already in use
kubectl get services -A

# 2. Pick a free IP in the service CIDR for the connected registry
AVAILABLE_IP="<VALID_IP>"
CONNECTED_REGISTRY_NAME="ContosoConnectedRegistry"

# 3. Generate the connection string (regenerates the sync token password)
CONNECTION_STRING=$(az acr connected-registry get-settings \
  --name "$CONNECTED_REGISTRY_NAME" \
  --registry "$ACR_NAME" \
  --parent-protocol https \
  --generate-password 1 \
  --query ACR_REGISTRY_CONNECTION_STRING \
  --output tsv --yes)

# 4. Write the protected settings file
jq -n --arg cs "$CONNECTION_STRING" '{connectionString: $cs}' > protected-settings-extension.json

# 5. Install the extension
az k8s-extension create \
  --cluster-name "<ARC_CLUSTER_NAME>" \
  --cluster-type connectedClusters \
  --extension-type Microsoft.ContainerRegistry.ConnectedRegistry \
  --name "$CONNECTED_REGISTRY_NAME" \
  --resource-group "<ARC_CLUSTER_RESOURCE_GROUP>" \
  --config service.clusterIP="$AVAILABLE_IP" \
  --config pvc.storageRequest=20Gi \
  --config cert-manager.install=false \
  --config-protected-file protected-settings-extension.json
# To use a non-default storage class, add: --config pvc.storageClassName=<storage-class-name>
```

#### PowerShell

```powershell
# 1. Check IPs already in use
kubectl get services -A

# 2. Pick a free IP in the service CIDR for the connected registry
$AvailableIp           = "<VALID_IP>"
$ConnectedRegistryName = "ContosoConnectedRegistry"

# 3. Generate the connection string (regenerates the sync token password)
$ConnectionString = az acr connected-registry get-settings `
  --name $ConnectedRegistryName `
  --registry $AcrName `
  --parent-protocol https `
  --generate-password 1 `
  --query ACR_REGISTRY_CONNECTION_STRING `
  --output tsv --yes
$ConnectionString = $ConnectionString -replace "`r", ""

# 4. Write the protected settings file
@{ connectionString = $ConnectionString } |
  ConvertTo-Json |
  Out-File protected-settings-extension.json -Encoding utf8

# 5. Install the extension
az k8s-extension create `
  --cluster-name "<ARC_CLUSTER_NAME>" `
  --cluster-type connectedClusters `
  --extension-type Microsoft.ContainerRegistry.ConnectedRegistry `
  --name $ConnectedRegistryName `
  --resource-group "<ARC_CLUSTER_RESOURCE_GROUP>" `
  --config service.clusterIP=$AvailableIp `
  --config pvc.storageRequest=20Gi `
  --config cert-manager.install=false `
  --config-protected-file protected-settings-extension.json
# To use a non-default storage class, add: --config pvc.storageClassName=<storage-class-name>
```

#### Verify

```bash
# Should show one connected-registry pod plus per-node containerd pods, all Running
kubectl get pods -n connected-registry

# Should report the connected registry as Online
az acr connected-registry list --registry "$ACR_NAME" --output table
```

> The IP you choose here is the `LocalConnectedRegistryIP` parameter required by `main.bicep`.

### 7. Make the image-pull credentials available to your workloads

Workloads pull from the connected registry using the client token (`all-repos-pull-token`) provisioned by `infra.bicep`. You need to get that token's credentials onto the cluster as a Kubernetes secret in the **namespace bound to your Custom Location** — the Workload Orchestration extension's identity is scoped to that namespace and may not have access to others. Pick the approach that matches your chart:

- **Option A — Sample chart in this repo.** [`charts/simple-chart`](../../charts/simple-chart) looks up the secret from a source namespace and copies it into the release namespace at install time (see [`image-pull-secret.yaml`](../../charts/simple-chart/templates/image-pull-secret.yaml)). Create the secret in the Custom Location namespace and reference it via `LocalConnectedRegistrySecretName` / `namespace` in `main.bicep`.
- **Option B — Your own chart.** Create the secret in the namespace where chart is deployed and reference it with `imagePullSecrets` in your pod spec.

#### Find the Custom Location namespace

```bash
az customlocation show \
  --resource-group "<CUSTOM_LOCATION_RESOURCE_GROUP>" \
  --name "<CUSTOM_LOCATION_NAME>" \
  --query "namespace" -o tsv
```

#### Bash

```bash
PULL_SECRET_NAME="my-acr-secret"
CL_NAMESPACE="workloadorchestration"
TOKEN_NAME="all-repos-pull-token"

# 1. Generate a password for the client token
TOKEN_PASSWORD=$(az acr token credential generate \
  --registry "$ACR_NAME" \
  --name "$TOKEN_NAME" \
  --password1 \
  --query "passwords[0].value" -o tsv)

# 2. Create the docker-registry secret in the Custom Location namespace
kubectl create secret docker-registry "$PULL_SECRET_NAME" \
  --namespace "$CL_NAMESPACE" \
  --docker-server="$AVAILABLE_IP" \
  --docker-username="$TOKEN_NAME" \
  --docker-password="$TOKEN_PASSWORD"
```

#### PowerShell

```powershell
$PullSecretName = "my-acr-secret"
$ClNamespace    = "workloadorchestration"
$TokenName      = "all-repos-pull-token"

# 1. Generate a password for the client token
$TokenPassword = az acr token credential generate `
  --registry $AcrName `
  --name $TokenName `
  --password1 `
  --query "passwords[0].value" -o tsv

# 2. Create the docker-registry secret in the Custom Location namespace
kubectl create secret docker-registry $PullSecretName `
  --namespace $ClNamespace `
  --docker-server=$AvailableIp `
  --docker-username=$TokenName `
  --docker-password=$TokenPassword
```
