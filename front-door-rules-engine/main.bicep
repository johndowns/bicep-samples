param frontDoorName string
param backendAddress string

var rulesEngineName = 'MyRulesEngine'

// Because of the way the Front Door rules engine works, we have to deploy this twice.
// The first time is required so that Front Door is available for the rules engine.
// The second time then attaches the rules engine to the Front Door instance.

module frontDoorDeployment1 'front-door.bicep' = {
  name: 'front-door-deployment-1'
  params: {
    frontDoorName: frontDoorName
    backendAddress: backendAddress
    rulesEngineId: ''
  }
}

resource rulesEngine 'Microsoft.Network/frontDoors/rulesEngines@2020-05-01' = {
  name: '${frontDoorName}/${rulesEngineName}'
  dependsOn: [
    frontDoorDeployment1
  ]
  properties: {
    rules: [
      {
        name: 'MyRule'
        priority: 1
        matchConditions: []
        action: {}
      }
    ]
  }
}

module frontDoorDeployment2 'front-door.bicep' = {
  name: 'front-door-deployment-2'
  dependsOn: [
    rulesEngine
  ]
  params: {
    frontDoorName: frontDoorName
    backendAddress: backendAddress
    rulesEngineId: rulesEngine.id
  }
}
