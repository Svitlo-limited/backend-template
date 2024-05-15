param name string
param location string = resourceGroup().location
param tags object = {}

param apiBaseUrl string
param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = ''
param serviceName string = 'web'
param customDomainName string = 'get-honey.ai'
param certificateId string = '/subscriptions/3ab1fecc-f7d3-4d78-a4d2-806f174d0ef6/resourceGroups/todocsharpsomeshit/providers/Microsoft.App/managedEnvironments/cae-seo7vwt2q2nku/managedCertificates/get-honey.ai-cae-seo7-240514112541'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource containerApp 'Microsoft.App/containerApps@2023-04-01' = {
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
            cpu: 1  // Updated to integer
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
            {
              name: 'REACT_APP_API_BASE_URL'
              value: apiBaseUrl
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = containerApp.identity.principalId
output SERVICE_WEB_NAME string = containerApp.name
output SERVICE_WEB_URI string = containerApp.properties.configuration.ingress.fqdn
output SERVICE_WEB_IMAGE_NAME string = containerApp.properties.template.containers[0].image
