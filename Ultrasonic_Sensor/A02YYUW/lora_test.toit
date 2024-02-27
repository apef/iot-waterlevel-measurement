import gpio
import uart
import writer show Writer
import reader show BufferedReader

// main: 
//   // loraModule := uart.Port --baud_rate=115200 --tx=gpio.Pin 1 --rx=gpio.Pin 3
//   port := uart.Port --rx=rx --baud-rate=9600 --tx=null

//     task:: readLora loraModule

main:
  // LoRa OTTA configuration variables for end device
  // device_eui := ""
  // app_eui := "0000000000000000"
  // app_key := ""
  // ul_dl_mode := ""
  // join_eui := "0000000000000000"

  device_eui := "70B3D57ED8002888"
  app_eui := "0000000000000000"
  app_key := "AE2EFAAF6DA69FFBED43FDB1A1A07384"
  ul_dl_mode := ""
  join_eui := "0000000000000000"

  tx := gpio.Pin 1
  rx := gpio.Pin 3  // Labeled as TX on the sensor.
  loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=null

  M5LoRa_config_OTTA loraModule device_eui app_eui app_key ul_dl_mode
  
  isconnected := false
  while isconnected == false:
   isconnected = m5LoRa_checkConnection loraModule
   if not isconnected:
    print "Retrying connection..."
    sleep --ms=1000


  // print "Prior to function"
  // task:: readLora loraModule
  // task:: writeLora loraModule "TestPing" true

readLora loraModule:
  print "LoraModule started."

  task::
      while true:
          // print "Reading:"
          sleep --ms=1000   
          sData := loraModule.read
          if not sData:
              break
          loraData := sData.to_string
          print "->$loraData"

writeLora loraModule textString inf_loop:
  writer := Writer loraModule
  print "Writing $(textString) to LoRa Module.."
  isDone := false
  task::

      while not isDone:
        writer.write textString
        sleep --ms=500

        if inf_loop == false:
          isDone = true
  
M5LoRa_config_OTTA loraModule device_eui app_eui app_key ul_dl_mode:
  print "Configurating LoRa Module OTTA.."
  writer := Writer loraModule

  writer.write "AT+CJOINMODE=0\r\n"
  writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
  writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
  writer.write "AT+CAPPKEY=" + app_key + "\r\n"
  writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
  print "LoRa Module OTTA set."
  
m5LoRa_checkConnection loraModule -> bool:
  isconnected := false
  print "Checking LoRa connection.."
  writer := Writer loraModule
  timeVal := 10
  writer.write "AT+CGMI?\r\n"

  sData := LoRaWaitMSG loraModule
  // task::
  //   sData := loraModule.read
  
  // task::
  //   while timeVal > 0:
  //     sleep --ms=1000
  //     timeVal = timeVal - 1

  // while sData == null or timeVal > 0:
  //   pass
  
  if sData == null:
    print "Connection was not established"
  
  if sData != null:
    print "Connection was established"
    isconnected = true

  return isconnected

m5LoRa_checkJoinStatus loraModule:
  responseStr := ""

  writer := Writer loraModule
  writer.write "AT+CSTATUS?\r\n"

  sData := task::LoRaWaitMSG loraModule
  
  
  if sData == null:
    print "Connection was not established"
  
  
LoRaWaitMSG loraModule:
  timeVal := 10
  sData := null
  task::
    sData = loraModule.read
  
  task::
    while timeVal > 0:
      sleep --ms=1000
      timeVal = timeVal - 1

  while sData == null or timeVal > 0:
    timewaste := ""
  
  if sData == null:
    print "Retries exceeded, no data was recieved."
  
  return sData

  
    // Wait
      
