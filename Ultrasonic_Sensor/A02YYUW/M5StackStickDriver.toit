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
import dartino_regexp.regexp show RegExp




checkDeviceConnect loraModule -> bool:
  print "Check device connect"
  response := ""
  writer := Writer loraModule
  isconnected := false
  // writer.write "AT+CGMI?\r\n"
 
  // task:: readLora loraModule
  // print "Task should be running in the background"
  response = waitMSG loraModule "AT+CGMI?\r\n" 5000
  print "Task running in background"
  sleep --ms=6000
  print "Returned, response: $(response)"

  re := RegExp "\nOK\n"
  // line := " AT+CGMI?\r\n\n+CGMI=ASR\nOK\n"
  check := re.has_matching response

  if check:
    print "REPONSE WAS OK!!!!"
    isconnected = true

  return isconnected




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

waitMSG loraModule command waitTime -> string:
  response := ""
  timeStart := Time.now

  reader := BufferedReader loraModule
  writer := Writer loraModule
  writer.write "AT+CGMI?\r\n"
  // print "WaitMSG"
  print "Wrote to device"
  while true:
    // print "$(timeStart.to-now.in-ms) -- $(waitTime)"
    if (timeStart.to-now.in-ms < waitTime):
      // print timeStart.to-now.in-ms
      line := reader.read-line
      // print line
      response += line + "\n"

      if line == "OK":
        print "OK WAS FOUND"
        break
      

    if (timeStart.to-now.in-ms > waitTime):
      print "Wait time is over... Retuning"
      break
  print "returning"
  // retString = response
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
  
  
// Sets the class for the device  
// mode  0: classA 1: classB 2: classC 
M5_SetClass loraModule mode:
  writer := Writer loraModule
  writer.write "AT+CCLASS=" + mode + "\r\n"
  print "LoRaWAN Class set"

// Setting the reception window parameters
M5_setRxWindow loraModule freq:
  writer := Writer loraModule
  writer.write "AT+CRXP=0,0," + freq + "\r\n"
  print "LoRaWAN RxWindow set"

// brief Setting the band mask
//For channels 0-7, the corresponding mask is 0001, for channels 8-15 it is 0002, and so on.
M5_setFreqMask loraModule mask:
  writer := Writer loraModule
  writer.write "AT+CFREQBANDMASK=" + mask + "\r\n"
  print "LoRaWAN Freqbandmask set"

// Joins the Node
M5_startJoin loraModule:
  writer := Writer loraModule
  writer.write "AT+CJOIN=1,0,10,8\r\n"
  print "Joining node call sent"


device_eui := "70B3D57ED8002888"
app_eui := "0000000000000000"
app_key := "AE2EFAAF6DA69FFBED43FDB1A1A07384"
ul_dl_mode := "2"
join_eui := "0000000000000000"
freq_mask := "0001"
RxWindow := "869525000"

main:
  tx := gpio.Pin 17
  rx := gpio.Pin 16  // Labeled as TX on the sensor.
  // loraModule  := uart.Port --rx=rx --baud-rate=115200 --tx=null
  // loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=tx
  loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=tx
  print "test"

  sleep --ms=1000
  isconnected := checkDeviceConnect loraModule

  if (isconnected):
    print "Device is connected"
  
  M5LoRa_config_OTTA loraModule device_eui app_eui app_key ul_dl_mode
  print 
  M5_SetClass loraModule "2"
  sleep --ms=1000
  M5_setFreqMask loraModule freq_mask
  sleep --ms=1000
  M5_setRxWindow loraModule "869525000"
  sleep --ms=1000
  M5_startJoin loraModule
  sleep --ms=1000
  // waitMSG loraModule 5000
  // print "Back to main"

  
  // waitMSG loraModule 5000
  // // // print check
  // print "Back to main2"
  // print "Back to main3"


  task:: readLora loraModule
  // task:: readLora loraModule2 2
  // task:: readLora loraModule3 3
  // task:: writeLora loraModule "TestPing" true

