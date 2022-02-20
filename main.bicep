@minLength(3)
@maxLength(11)
param storagePrefix string
param storageSKU string = 'Standard_LRS'
param location string = resourceGroup().location

@description('This is a storage blob container that captures incoming breadcrumb or rmisfiles.')
param containerName string = 'rmisfiles'

@description('This is a storage queue which is the destination endpoint for storage event subscription')
param queueName string = 'rimsfiles'

// Create unique string for storage name.
var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

// Deploy Azure Storage resource and setting its name property  to unique value 
// The property uniqueStorageName is created using storage prefix literal 
// and unique string function. 
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
  //Deploy Azure Storage queues by setting queue services name property to 'default'
  //Then create the actuall storage queue resource with desired queue name 
  //E.g. setting value to 'rmifiles' will create a storage queue with queue name to rmifiles.

  resource queueServices 'queueServices@2021-08-01' = {
    name: 'default'
    
    // Set name of Storage queue.
    resource queue 'queues' = {
      name: queueName
    }
  }

  // Deploy Azure Storage blobs by setting blob servcies name property to 'defualt'
  // Then create the actuall blob container resource with desired container name 
  // E.g. setting value to rmifiles will create a storage blob with container name to rmifiles.
  resource blobservices 'blobServices' = {
    name: 'default'

    // Set name of Blob container
    resource container 'containers' = {
      name: containerName
    } 
  } 
}

output storageEndpoint object = stg.properties.primaryEndpoints


