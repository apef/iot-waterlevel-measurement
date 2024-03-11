import .M5LoRaDriver
import dyp-a01 show DYP-A01
import .dec_to_hex
import .sensorModule
import gpio
import math
import esp32

main:
  m5_tx := 17
  m5_rx := 16
  sensor_tx := 4
  sensor_rx := 3

  //Device OTAA
  device_eui := "70B3D57ED00656F9"
  app_eui := "0000000000000001"
  app_key := "4DC5446B5A56C2414924C00EFCF19738"

  iotDevice := M5LoRaDevice m5_tx m5_rx device_eui app_eui app_key
  sensorModule := sensorModule sensor_tx sensor_rx

  iotDevice.start
  sensorModule.start

  print "Sleep for 30 seconds."
  sleep --ms=30000
  sendSensorData iotDevice sensorModule
  sleep --ms=1000
  esp32.deep-sleep (Duration --s=10)

sendSensorData loraDevice sensorModule:
  sensorValue := sensorModule.get_sensorValue
  // print "Sending sensor value in 2 minutes"
  // sleep --ms=120000
  // sleep --ms=10000
  print "SENDING DATA"
  dataStrLen := "$(sensorValue)".size
  // dataStrLen++
  prependAmount := math.pow 10 dataStrLen

  print prependAmount
  data := sensorValue + prependAmount
  print data

  loraDevice.M5_sendMSG 1 3 data
