param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = ''
param serviceName string = 'api'
param redisServiceName string = 'redis'
param postgresServiceName string = 'postgres'
param customDomainName string = 'api.get-honey.ai'
param certificateId string = '3ab1fecc-f7d3-4d78-a4d2-806f174d0ef6'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource redis 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: redisServiceName
}

resource postgres 'Microsoft.App/containerApps@2022-11-01-preview' existing = {
  name: postgresServiceName
}

resource containerApp 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': serviceName })
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppsEnvironmentName)
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        customDomains: [
          {
            name: customDomainName
            certificateId: certificateId
            bindingType: 'SniEnabled'
          }
        ]
        allowInsecure: false
      }
      registries: [
        {
          server: containerRegistryName
          username: containerRegistryName
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'main'
          image: !empty(imageName) ? imageName : 'nginx:latest'
          resources: {
            cpu: '1.0'
            memory: '2.0Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      serviceBinds: [
        {
          serviceId: redis.id
          name: redis.name
        }
        {
          serviceId: postgres.id
          name: postgres.name
        }
      ]
    }
  }
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = containerApp.identity.principalId
output SERVICE_API_NAME string = containerApp.name
output SERVICE_API_URI string = containerApp.properties.configuration.ingress.fqdn
output SERVICE_API_IMAGE_NAME string = containerApp.properties.template.containers[0].image
