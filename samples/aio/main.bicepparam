using './main.bicep'

param schemaRegistryId = '<SCHEMA_REGISTRY_RESOURCE_ID>'
param adrNamespaceId = '<ADR_NAMESPACE_RESOURCE_ID>'
param targets = [
  {
    name: '<TARGET_NAME>'
    resourceGroupName: '<TARGET_RESOURCE_GROUP_NAME>'
    configuration: {
      clusterName: '<arc enabled cluster name>'
      customLocationName: '<aio custom location name>'
      aioInstanceName: '<aio instance name>'
    }
  }
]
