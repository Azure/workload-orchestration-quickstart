# Getting Started with Pipelines

This repo includes three CI/CD pipelines for validating, syncing, and deploying Workload Orchestration resources. Each pipeline is available for both **GitHub Actions** and **Azure DevOps Pipelines**.

## Pipelines Overview

| Pipeline | GitHub Actions | Azure DevOps | Trigger |
|---|---|---|---|
| **Validate** | `.github/workflows/validate-bicep.yml` | `.pipelines/validate-bicep.yml` | Pull requests to `main` |
| **Sync** | `.github/workflows/sync-bicep.yml` | `.pipelines/sync-bicep.yml` | Push to `main` (or manual) |
| **Deploy** | `.github/workflows/deploy-by-name.yml` | `.pipelines/deploy-by-name.yml` | Manual trigger |

### Validate

Runs on pull requests to `main`. Validates Bicep templates against Azure using deployment stack validation and posts the result as a PR comment.

### Sync

Runs on push to `main`. Deploys resource definitions (sites, targets, schemas, solution templates, etc.) to Azure via a Deployment Stack.

### Deploy

Manually triggered. Deploys a specific solution template version to a target cluster. Requires two inputs:
- **Target Name** — e.g., `ContosoTarget`
- **Solution Template Name/Version** — e.g., `SampleApp/1.0.0`

**How it works:**
1. **Resolve** — reads `workload-orchestration.yaml` to find the resource group, queries the deployment stack for the target and solution template version resource IDs by name.
2. **Deploy** — deploys the resolved solution template version to the resolved target.

---

## Setup for GitHub Actions

1. **Workflows are pre-configured** in `.github/workflows/`. They activate automatically once the repo is forked or copied over.

2. **Set up authentication** — configure OIDC-based Azure login by following the [Authentication Setup](setup-authentication.md#set-up-azure-authentication-for-github-actions).

3. **Verify** — open a PR to `main` and confirm the **WO Validate** workflow runs.

---

## Setup for Azure DevOps Pipelines

1. **Create a service connection** — follow the [Authentication Setup](setup-authentication.md#set-up-azure-authentication-for-azure-devops-pipelines) to create an Azure Resource Manager service connection.

2. **Register each pipeline** in Azure DevOps:
   - Go to **Pipelines → New Pipeline**, select your repository source.
   - Select your repository and choose **Existing Azure Pipelines YAML file**.
   - Point to each file under `.pipelines/`:
     - `.pipelines/validate-bicep.yml`
     - `.pipelines/sync-bicep.yml`
     - `.pipelines/deploy-by-name.yml`

3. **Set up build validation** — Azure DevOps does not run PR pipelines automatically. Add a branch policy so `validate-bicep` runs on every PR targeting `main`:
   - Go to **Repos → Branches**, hover over `main`, click the **⋯** menu, and choose **Branch policies**.
   - Scroll to **Build Validation** and click **+** to add a new policy.

4. **Grant build service to comment on PR** - Grant the build service access to **Contribute to pull request**   

5. **Verify** — open a PR to `main` and confirm the **Validate Bicep** pipeline runs automatically.