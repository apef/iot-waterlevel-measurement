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
  device_eui := ""
  app_eui := ""
  app_key := ""
  ul_dl_mode := ""

  tx := gpio.Pin 1
  rx := gpio.Pin 3  // Labeled as TX on the sensor.
  loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=null

  print "Prior to function"
  task:: readLora loraModule
  task:: writeLora loraModule "TestPing" true

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
  print "Initializing LoRa Module.."
  writer := Writer loraModule

  writer.write "AT+CJOINMODE=0\r\n"
  writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
  writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
  writer.write "AT+CAPPKEY=" + app_key + "\r\n"
  writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
  