import esp32
import system.services
import system.storage
import .DistanceSensorService
import .LoRaConnectionService
import .EnvironmentSensorService
import .BatteryLevelService
import math show pow

main:
  m5_tx := 17
  m5_rx := 16
  sensor_tx := 0 // the device will stop responding when set to the 'correct' pin (1 in our case), however it is not needed and is therefore set to 0. 
  sensor_rx := 3
  adc_pin := 32
  bat_pin := 34
  referenceDistance := 4000 // Must be set to the correct reference distance, for valid measurments.

  //-------Device OTAA-----------
  device_eui := "" 
  app_eui    := ""
  app_key    := ""
  // ----- Must be set to join a network
  
  spawn:: // Starts up another container to run the specified service in
    loraservice := LoraConnectionServiceProvider
    loraservice.install
    task:: loraservice.run m5_tx m5_rx device-eui app_eui app_key
  
  spawn::  
    sensorservice := DistanceSensorServiceProvider
    sensorservice.install
    task:: sensorservice.run --tx=sensor_tx --rx=sensor_rx --refDistance=referenceDistance

  spawn::
    envservice := EnvironmentSensorServiceProvider
    envservice.install
    task:: envservice.run --adc-pin=adc_pin
  
  spawn::
    batservice := BatteryLevelServiceProvider
    batservice.install
    task:: batservice.run --adc-pin=bat-pin

  // Define the service clients.
  loraclient   := LoraConnectionServiceClient
  sensorclient := DistanceSensorServiceClient
  envclient    := EnvironmentSensorServiceClient
  batclient    := BatteryLevelServiceClient


  sleep --ms=1000 // Sleep while the device is connecting to LoRaWAN

  // Opening up the communication to the services
  loraclient.open
  sensorclient.open
  envclient.open
  batclient.open
  

  // Periodic tasks
  task::
    while true:
      temp := envclient.temp
      humidity := envclient.humidity
      indexTempValue := setIndex temp.to-int 2
      indexHumidityValue := setIndex humidity.to-int 3
    
      loraclient.sendMSG indexTempValue
      sleep --ms=1000
      loraclient.sendMSG indexHumidityValue
      sleep --ms=50000
  
  task::    
    while true:
      dist := sensorclient.distance
      indexedValue := setIndex dist 1
      loraclient.sendMSG indexedValue
      sleep --ms=30000

  task::
    while true:
      batlvl := batclient.batlvl
      indexedValue := setIndex batlvl 4
      loraclient.sendMSG indexedValue
      sleep --ms=60000

  sleep --ms=120000             // Keep the device working and send data during its awake time of 2 minutes
  print "Entering deepsleep"
  esp32.deep-sleep (Duration --s=900) // Enter deep-sleep for 15 minutes


// Prepends a specific index to a value
setIndex value/any index/int -> int:
  strValue := "$(value)"  // 'casting' to a string to find out the length of the value
  indexedValue := value + (index * (pow 10 (strValue.size)))
  return indexedValue.to-int
     