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
  
  resource queueServices 'queueServices@2021-08-01' existing = {
    name: 'default'
    
    resource queue 'queues' = {
      name: queueName
    }
  }

  resource blobservices 'blobServices' existing = {
    name: 'default'

    resource container 'containers' = {
      name: containerName
    } 
  } 
}

resource egrid 'Microsoft.EventGrid/eventSubscriptions@2021-12-01' = {
  name: 'esub'
  scope: stg
  properties: {
    destination: {
      endpointType: 'StorageQueue'
      properties: {
        queueName: queueName
        resourceId: stg::queueServices::queue.id
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          operatorType: 'StringEndsWith' 
          values: [
            '.csv'
          ]
        }
      ]
    }
  }
}

output storageEndpoint object = stg.properties.primaryEndpoints


