@description('The name of the Azure Functions application in which to create the function. This must be globally unique.')
param functionAppName string

@description('The name of the Service Bus connection string app setting.')
param serviceBusConnectionAppSettingName string

@description('The list of topics, for which each will have a send function created.')
param serviceBusTopicFunctions array

resource functionApp 'Microsoft.Web/sites@2020-06-01' existing = {
  name: functionAppName
}

// TODO combine the below - this will probably require constructing a binding dynamically, which will require variable loops

resource queueFunction 'Microsoft.Web/sites/functions@2020-06-01' = [for serviceBusTopicFunction in serviceBusTopicFunctions: {
  name: serviceBusTopicFunction.functionName
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'anonymous'
          methods: [
            'post'
          ]
        }
        {
          name: '$return'
          type: 'http'
          direction: 'out'
        }
        {
          name: 'outputMessage'
          type: 'serviceBus'
          topicName: serviceBusTopicFunction.topicName
          connection: serviceBusConnectionAppSettingName
          direction: 'out'
        }
      ]
    }
    files: {
      'run.csx': '''
        #r "Newtonsoft.Json"
        using System.Net;
        using Microsoft.AspNetCore.Mvc;
        using Microsoft.Extensions.Primitives;
        using Newtonsoft.Json;

        public static async Task<IActionResult> Run(HttpRequest req, ILogger log, IAsyncCollector<string> outputMessage)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            
            outputMessage.Add(requestBody);
            return new OkObjectResult("Sent message to topic.");
        }
      '''
    }
  }
}]
