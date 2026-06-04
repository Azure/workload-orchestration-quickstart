# Workload Orchestration — Github & ADO Jump Start

Manage Workload Orchestration resources as **Bicep templates in Github / ADO** with automated validation, sync via Azure Deployment Stacks, customizable resource protection settings, and solution deployment powered by canned pipelines for GitHub and Azure DevOps.

## Contents

- [Getting Started](#getting-started)
- [Repository Structure](#repository-structure)
- [Samples](#samples)
- [Bicep Modules](#bicep-modules)

## Getting Started

1. **Fork / Push** this repository into GitHub or Azure DevOps.
2. **Set up pipelines and azure authentication:** Follow the [Pipelines Setup](docs/pipelines.md)
3. **Configure deployment settings** in `workload-orchestration.yaml` - see [Repository Structure](#repository-structure) and [Customize Resource Management](docs/resource-management-customization.md) for details.
4. **Author your resources** - define schemas, solution templates, config templates, and their versions in your Bicep templates. Set the `templateFile` field in `workload-orchestration.yaml` to point to your top-level template.
5. **Push a branch, open a PR**, and the validation workflow runs automatically.
6. **Merge the PR** to `main` - the sync workflow triggers and syncs your resources to Azure.
7. **Deploy to your cluster** - go to **Deploy by Name**, trigger, and provide the target name and solution template version. See [Pipelines](docs/pipelines.md) for details about deploy.

## Repository Structure

| Path                                | Purpose                                                                                                                                                                                                                |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `workload-orchestration.yaml`       | Central config file specifying target resource group, Bicep template, deny settings, and resource lifecycle behavior. See [Customize Resource Management](docs/resource-management-customization.md) for more details. |
| `workload-orchestration/main.bicep` | Entry point template. You can rename, restructure, or replace it - all resources in the referenced template and modules are deployed together.                                                                         |
| `workload-orchestration/modules/`   | Optional reusable Bicep modules that simplify defining Workload Orchestration resources. See [Bicep Modules](#bicep-modules).                                                                                    |
| `.github/workflows/`                | GitHub Action Workflows: validate, sync, manual deploy - See [Pipelines](docs/pipelines.md) for details and setup.                                                                                                     |
| `.pipelines/`                       | Azure DevOps Pipelines: validate, sync, manual deploy - See [Pipelines](docs/pipelines.md) for details and setup.                                                                                                      |
| `samples/`                          | [Ready-to-use sample templates](samples/README.md) - for example: basic, staging.                                                                                                                                      |

## Samples

The [`samples/`](./samples/) folder contains ready-to-use Bicep templates for common Workload Orchestration scenarios. Each sample is a self-contained set of files and deploy with minimal changes.

| Sample                                          | Description                                                                                                                                              |
|-------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| [quickstart-basic](./samples/quickstart-basic/) | Sets up Workload Orchestration to deploy solution on cluster. |
| [staging-solution](./samples/staging-solution/) | Sets up Workload Orchestration with image staging.                                                                                                     |

## Bicep Modules

See [workload-orchestration/modules/README.md](workload-orchestration/modules/README.md) for details on the reusable Bicep modules included in this repository.
