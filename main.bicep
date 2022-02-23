@minLength(3)
@maxLength(11)
param storagePrefix string
param storageSKU string = 'Standard_LRS'
param location string = resourceGroup().location

@description('This is a storage blob container that captures incoming breadcrumb or rmisfiles.')
param containerName string = 'rmisfiles'

@description('This is a storage queue which is the destination endpoint for storage event subscription')
param queueName string = 'rimsfiles'

// function app creation variables
//param functionRuntime string = 'dotnet'
param appNamePrefix string = uniqueString(resourceGroup().id)
//param workspaceResourceId string = 'la-${uniqueString(resourceGroup().id)}'


// end of function app creation variables 

// Create unique string for storage name.
var uniqueStorageName = '${storagePrefix}${uniqueString(resourceGroup().id)}'

// Variable for app function 
var appTags = {
  AppID: 'EIR #234'
  AppName:'LDE Logical Delivery Events'
  CostCenter: 'ITAS'
}
var appServiceName = '${appNamePrefix}-appservice'
var appInsightsName = '${appNamePrefix}-appinsights'
var storageAccountName = format('{0}sta', replace(appNamePrefix, '-', ''))
var logAnalyticsWorkspaceName = '${appNamePrefix}-la-workspace'

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
  tags: appTags
  
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

resource systopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: 'systopic'
  location: location
  properties: {
    source: stg.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
  tags: appTags
}

resource systemtopiceventsub 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
  parent: systopic
  name: 'systopevnsub'
   properties: {
    destination: {
      endpointType: 'StorageQueue'
       properties: { 
        queueName: queueName
        resourceId: stg.id
      }
    }

    eventDeliverySchema: 'EventGridSchema'
      filter: {
      subjectBeginsWith: '/blobServices/default/containers/${stg::blobservices::container.name}'
      subjectEndsWith: '.csv' 
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
}

// Storage Account for Function App .
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  tags: appTags
}

// Blob Services for Storage Account
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' = {
  parent: storageAccount

  name: 'default'
  properties: {
    cors:{
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Log Analytics neede for App Insights instantiation
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name:  logAnalyticsWorkspaceName
  location: location 
  tags: appTags
  properties: {
    features: {
      enableLogAccessUsingOnlyResourcePermissions: false
      immediatePurgeDataOn30Days: true
    }
    sku: {
      name: 'PerGB2018'
    } 
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// App Insights resource
resource appInsights  'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: appTags
}

// App Service
resource appService 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: appServiceName
  location: location
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
  tags: appTags
}

resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'mystorage'
  location: location
  sku: { 
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Function App

output storageEndpoint object = stg.properties.primaryEndpoints


