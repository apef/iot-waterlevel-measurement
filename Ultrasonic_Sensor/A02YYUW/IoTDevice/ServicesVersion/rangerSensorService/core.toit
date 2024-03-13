import gpio
import system.services
import dyp_a01 show DYP_A01

import .RangerSensorService
import .LoRAConnectionService

main:
  m5_tx := 17
  m5_rx := 16
  sensor_tx := 4
  sensor_rx := 3

  // //Device OTAA
  device_eui := "70B3D57ED00656F9"
  app_eui := "0000000000000001"
  app_key := "4DC5446B5A56C2414924C00EFCF19738"

  spawn::
    loraservice := LoraConnectionServiceProvider
    loraservice.install
    task:: loraservice.run m5_tx m5_rx device-eui app_eui app_key
  
  spawn::  
    sensorservice := RangeSensorServiceProvider
    sensorservice.install
    task:: sensorservice.run --rx=sensor_rx

  loraclient := LoraConnectionServiceClient
  sensorclient := RangeSensorServiceClient
  loraclient.open
  sensorclient.open
  
  (Duration --s=1).periodic:
    print sensorclient.range
  // while true:
  //   print "range = $(loraclient.sendMSG "test") mm"
  //   sleep --ms=1_000