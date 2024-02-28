// /*! @brief Check that LoRaWAN devices are connected
//  *  @return Return 1 if the connect successful, otherwise 0.. */
//  bool M5_LoRaWAN::checkDeviceConnect() {
//   String restr;
//   writeCMD("AT+CGMI?\r\n");
//   restr = waitMsg(500);
//   if (restr.indexOf("OK") == -1) {
//       return false;
//   } else {
//       return true;
//   }
// }

import reader show BufferedReader
import writer show Writer
import uart
import gpio

device_eui := "70B3D57ED8002888"
app_eui := "0000000000000000"
app_key := "AE2EFAAF6DA69FFBED43FDB1A1A07384"
ul_dl_mode := ""
join_eui := "0000000000000000"


checkDeviceConnect loraModule:
  print "Check device connect"
  response := ""
  writer := Writer loraModule

  writer.write "AT+CGMI?\r\n"
  print "Wrote to device"
  task:: readLora loraModule
  print "Task should be running in the background"
  // response = waitMSG loraModule 5000




// /*! @brief Waiting for a period of time to receive a message
//  *  @param time Waiting time (milliseconds)
//  *  @return Received messages */
//  String M5_LoRaWAN::waitMsg(unsigned long time) {
//   String restr;
//   unsigned long start = millis();
//   while (1) {
//       if (_serial->available() || (millis() - start) < time) {
//           String str = _serial->readString();
//           restr += str;
//       } else {
//           break;
//       }
//   }
//   return restr;
// }

waitMSG loraModule waitTime -> string:
  response := ""
  timeStart := Time.now

  reader := BufferedReader loraModule
  writer := Writer loraModule

  print "WaitMSG"
  while true:
    print "$(timeStart.to-now.in-ms) $(waitTime)"
    if (timeStart.to-now.in-ms < waitTime):
      // print timeStart.to-now.in-ms
      response += reader.read-line
    
    if (timeStart.to-now.in-ms > waitTime):
      break
  print "returning"
  return response


M5LoRa_config_OTTA loraModule device_eui app_eui app_key ul_dl_mode:
  print "Configurating LoRa Module OTTA.."
  writer := Writer loraModule

  writer.write "AT+CJOINMODE=0\r\n"
  writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
  writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
  writer.write "AT+CAPPKEY=" + app_key + "\r\n"
  writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
  print "LoRa Module OTTA set."

main:
  tx := gpio.Pin 17
  rx := gpio.Pin 16  // Labeled as TX on the sensor.
  // loraModule  := uart.Port --rx=rx --baud-rate=115200 --tx=null
  // loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=tx
  loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=tx
  print "test"

  sleep --ms=1000
  checkDeviceConnect loraModule
  // M5LoRa_config_OTTA loraModule device_eui app_eui app_key ul_dl_mode
  // waitMSG loraModule 5000
  // print "Back to main"

  
  // waitMSG loraModule 5000
  // // // print check
  // print "Back to main2"
  // print "Back to main3"


  // task:: readLora loraModule
  // task:: readLora loraModule2 2
  // task:: readLora loraModule3 3
  // task:: writeLora loraModule "TestPing" true

readLora loraModule:
  print "LoraModule started."
  
  writer := Writer loraModule
  reader := BufferedReader loraModule

  task::
      while true:
          sleep --ms=2000   
          sData := reader.read-line
          if not sData:
              break
          loraData := sData.to_string
          print "$loraData"


