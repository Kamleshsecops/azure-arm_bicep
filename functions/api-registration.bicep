/*
  Register an Azure Functions into API Management
*/

// === PARAMETERS ===

@description('The organization name')
@minLength(3)
@maxLength(3)
param organizationName string

@description('The application name')
@minLength(2)
@maxLength(14)
param applicationName string

@description('The host name of the deployment stage')
@minLength(3)
@maxLength(5)
param hostName string

@description('The ARM templates version')
@minLength(1)
param templateVersion string


@description('The products to link with the API Management API')
param apiManagementProducts array = []

@description('Whether an API Management subscription is required')
param apiManagementSubscriptionRequired bool = true

@description('The API Management API version')
@minLength(1)
param apiManagementVersion string = 'v1'

@description('The OpenAPI link, relative to the application host name')
@minLength(1)
param relativeOpenApiUrl string = '/api/swagger.json'

@description('The relative URL of the Functions application host')
@minLength(1)
param relativeFunctionsUrl string = '/api'

@description('The OpenID configuration for authentication')
param openIdConfiguration object = {}

@description('The CORS authorized origins, comma-separated')
param apiCorsAuthorized string = ''

@description('The deployment location')
param location string = resourceGroup().location

// === VARIABLES ===

@description('The region name')
var regionName = loadJsonContent('../modules/global/regions.json')[location].name

@description('Global & naming conventions')
var conventions = json(replace(replace(replace(replace(loadTextContent('../modules/global/conventions.json'), '%ORGANIZATION%', organizationName), '%APPLICATION%', applicationName), '%HOST%', hostName), '%REGION%', regionName))

// === EXISTING ===

@description('Functions application')
resource fn 'Microsoft.Web/sites@2021-03-01' existing = {
  name: '${conventions.naming.prefix}${conventions.naming.suffixes.functionsApplication}'
}

// === RESOURCES ===

@description('Resource groupe tags')
module tags '../modules/global/tags.bicep' = {
  name: 'Resource-Tags'
  params: {
    organizationName: organizationName
    applicationName: applicationName
    hostName: hostName
    regionName: regionName
    templateVersion: templateVersion
    disableResourceGroupTags: true
  }
}

@description('API Management backend & API registration')
module apimBackend '../modules/applications/functions/api-management-backend.bicep' = if (!empty(apiManagementProducts)) {
  name: 'Resource-ApiManagementBackend'
  params: {
    referential: tags.outputs.referential
    conventions: conventions
    functionsAppName: fn.name
    relativeFunctionsUrl: relativeFunctionsUrl
    apiVersion: apiManagementVersion
    subscriptionRequired: apiManagementSubscriptionRequired
    products: apiManagementProducts
    relativeOpenApiUrl: relativeOpenApiUrl
    openIdConfiguration: openIdConfiguration
    apiCorsAuthorized: apiCorsAuthorized
  }
}
