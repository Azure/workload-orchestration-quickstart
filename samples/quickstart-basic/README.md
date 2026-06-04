# Quickstart: Create a Basic Solution

This sample sets up a complete Workload Orchestration environment to deploy solution on cluster.

## What this sample does

It deploys the public [`podinfo`](https://github.com/stefanprodan/podinfo) Helm chart (`oci://ghcr.io/stefanprodan/charts/podinfo`, version `6.9.3`) as a solution called **QualityApp** to an Arc-connected cluster, using a minimal Workload Orchestration topology:

- **Context** `ContosoContext` — declares the **capabilities** (`Quality`, `Manufacturing`, `Retail`) and **hierarchies** (`Department`, `Unit`) available in this environment.
- **Site** `ContosoSite` + **Site Reference** — places the cluster within the hierarchy.
- **Target** `ContosoTarget` — binds to your Custom Location, declares it supports capabilities `Quality`, `Manufacturing`, `Retail` at `Unit` level.
- **Solution Template** `QualityApp` (v `1.0.0`) — declares it **requires** capabilities `Quality` and `Retail`. It can only be deployed to a target that advertises those capabilities — which `ContosoTarget` does.

### Capabilities

Capabilities are labels you define on the context and use to match solutions to targets. A solution template can be deployed to a target **only if** the target's capability set is a superset of the solution's. In this sample:

| Resource | Capabilities |
| --- | --- |
| `ContosoContext` (available) | `Quality`, `Manufacturing`, `Retail` |
| `ContosoTarget` (supports) | `Quality`, `Manufacturing`, `Retail` |
| `QualityApp` solution (requires) | `Quality`, `Retail` |

Result: `QualityApp` is deployable to `ContosoTarget`. If you removed `Quality` from the target's capabilities, deployment would be rejected.

### Config keys and how they reach the app

The solution template's `configurations` block defines key/value pairs that get rendered as Helm chart values at deploy time:

```yaml
configs:
  AppName: QualityApp
  fullnameOverride: qualityapp
```

These keys are passed straight through to the `podinfo` Helm chart as values:

- `AppName` — a custom value surfaced to the app (e.g. usable in templates / env vars).
- `fullnameOverride` — a standard Helm convention; here it forces the released Kubernetes resources to be named `qualityapp` instead of the chart-generated name.

To add or change configuration, edit the `configurations` block in [`solutionTemplate.bicep`](./solutionTemplate.bicep). Anything you add under `configs:` becomes a chart value at deploy time.

## Prerequisites
- Fork / Push this repository into GitHub or Azure DevOps.
- Complete the [Pipelines Setup](../../docs/pipelines.md).
- An **Arc-connected Kubernetes cluster** with the Workload Orchestration extension installed and a **Custom Location** configured.

## Part 1: Sample

### Step 1. Author your resources

1. Update `templateFile` in `workload-orchestration.yaml` to point to the sample:

   ```yaml
   templateFile: "./samples/quickstart-basic/main.bicep"
   ```

2. Replace `<CUSTOM_LOCATION_ID>` in `main.bicep` with your Custom Location ARM resource ID.

3. Set your resource group name in `workload-orchestration.yaml`.

### Step 2. Validate and sync

1. Push a branch, open a PR — the validation workflow runs automatically.
2. Merge the PR to `main` — the sync workflow deploys your resource definitions to Azure via Deployment Stacks.

### Step 3. Deploy to your cluster (manual step)

Manually trigger the **Deploy by Name** workflow to deploy your solution to the cluster.

> [!IMPORTANT]
> Merging to `main` only syncs resource definitions to Azure. To **deploy your application to a cluster**, you must manually trigger the **Deploy by Name** workflow from  GitHub / Azure DevOps.
