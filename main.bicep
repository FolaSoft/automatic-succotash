@minLength(3)
@maxLength(11)
param storagePrefix string

param storageSKU string = 'Standard_LRS'

param location string = resourceGroup().location

@description('This is a storage container that captures incoming breadcrumb or rmisfiles.')
param containerName string = 'rmisfiles'

@description('This is a storage queue which is the destination endpoint for storage event subscription')
param queueName string = 'rimsfiles'

var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

resource stg 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: uniqueStorageName
  location: location
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties:{
    supportsHttpsTrafficOnly: true
    
  }
  
  resource queue 'queueServices@2021-08-01' = {
    name: queueName
    
    resource qservice 'queues' = {
      name: 'testqueue'
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${stg.name}/default/${containerName}'
}

output storageEndpoint object = stg.properties.primaryEndpoints


