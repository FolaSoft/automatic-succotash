@minLength(3)
@maxLength(11)
param storagePrefix string

param storageSKU string = 'Standard_LRS'

param location string = resourceGroup().location

@description('This container captures incoming rmisfiles.')
param containerName string = 'rmisfiles'

var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties:{
    supportsHttpsTrafficOnly: true
  }
}
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${stg.name}/default/${containerName}'
}



output storageEndpoint object = stg.properties.primaryEndpoints


