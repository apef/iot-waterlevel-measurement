
import dyp_a01 show DYP_A01
import reader show BufferedReader
import writer show Writer
import uart
import gpio
import dartino_regexp.regexp show RegExp
import .dec_to_hex
import math


class M5LoRaDevice:
  isconnected := false
  sensorValue := 0

  // tx := gpio.Pin 17
  // rx := gpio.Pin 16
  loraModule := null

  //Device OTAA
  device_eui := ""
  app_eui := ""
  app_key := ""

  join_eui := "0000000000000000"
  freq_mask := "0001"
  RxWindow := "869525000"
  spreadFactor := "9"
  ul_dl_mode := "2"
    
  
  constructor tx_pin/int rx_pin/int device_ui/string app_eui/string app_key/string:
    tx := gpio.Pin tx_pin
    rx := gpio.Pin rx_pin
    loraModule = uart.Port --rx=rx --baud-rate=115200 --tx=tx


    //Device OTAA
    device_eui = "70B3D57ED00656F9"
    app_eui = "0000000000000001"
    app_key = "4DC5446B5A56C2414924C00EFCF19738"

  start:

    task:: checkDeviceConnect
    
    while not isconnected:
      sleep --ms=100

    print "Device is connected."
    
    task:: readLora 
      
    writer := Writer loraModule

    sleep --ms=1000
    M5LoRa_config_OTTA device_eui app_eui app_key ul_dl_mode
    sleep --ms=1000
    writer.write "AT+CSAVE\r\n"
    print "CSAVE CONFIG.."
    sleep --ms=1000
    writer.write "AT+IREBOOT=0\r\n"
    print "IREBOOT.."
    sleep --ms=1000


    M5_setWorkMode "2"

    M5_setRxWindow "869525000" spreadFactor
    sleep --ms=1000

    // writer.write "AT+CDEVEUI?\r\n"
    // print "Reading devUI.."

    // writer.write "AT+CAPPEUI?\r\n"
    // print "Reading APPEUI"
    // writer.write "AT+CAPPKEY?\r\n"
    // print "Reading APPKEY"

    sleep --ms=5000
    M5_startJoin


  checkDeviceConnect:
    print "Check device connect"
    response := ""
    writer := Writer loraModule
  
    response = waitMSG "AT+CGMI?\r\n" 5000
    print "Task running in background"
    sleep --ms=6000
    print "Returned, response: $(response)"
  
    re := RegExp "\nOK\n"
    check := re.has_matching response
  
    if check:
      print "REPONSE WAS OK!!!!"
      isconnected = true
  
  waitMSG command waitTime -> string:
    response := ""
    timeStart := Time.now
  
    reader := BufferedReader loraModule
    writer := Writer loraModule
    writer.write command

    while true:
      if (timeStart.to-now.in-ms < waitTime):
        line := reader.read-line
        response += line + "\n"
  
        if line == "OK":
          print "OK WAS RECIEVED"
          break
        
        if line == "FAIL":
          print "FAIL WAS RECIEVED"
          break
  
      if (timeStart.to-now.in-ms > waitTime):
        print "Wait time is over... Retuning"
        break
    print "returning"
    return response
  
  
  M5LoRa_config_OTTA device_eui app_eui app_key ul_dl_mode:
    print "Configurating LoRa Module OTTA.."
    writer := Writer loraModule
  
    writer.write "AT+CJOINMODE=0\r\n"
    sleep --ms=50
    writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPKEY=" + app_key + "\r\n"
    // writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
    print "LoRa Module OTTA set."
  
  
  M5LoRa_config_ABP device_eui device_addr app_skey net_skey ul_dl_mode:
    writer := Writer loraModule
  
    writer.write "AT+CJOINMODE=1\r\n"
    writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
    writer.write "AT+CDEVADDR=" + device_addr + "\r\n"
    writer.write "AT+CAPPSKEY=" + app_skey + "\r\n"
    writer.write "AT+CNWKSKEY=" + net_skey + "\r\n"
    writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
    print "LoRa Module ABP set."
  
  
  readLora:
    print "LoraModule started."
    
    writer := Writer loraModule
    reader := BufferedReader loraModule
  
    task::
        while true:
            sleep --ms=30   
            sData := reader.read-line
            if not sData:
                break
            loraData := sData.to_string
            print "$loraData"
    
  // Sets the class for the device  
  // mode  0: classA 1: classB 2: classC 
  M5_SetClass mode:
    writer := Writer loraModule
    writer.write "AT+CCLASS=" + mode + "\r\n"
    print "LoRaWAN Class set"
  
  // Setting the reception window parameters
  M5_setRxWindow freq spreadFactor:
    writer := Writer loraModule
    // writer.write "AT+CRXP=0,0," + freq + "\r\n"
    writer.write "AT+CRXP=$(freq),$(spreadFactor)"+ "\r\n"
    print "LoRaWAN RxWindow set"
  
  // brief Setting the band mask
  //For channels 0-7, the corresponding mask is 0001, for channels 8-15 it is 0002, and so on.
  M5_setFreqMask mask:
    writer := Writer loraModule
    writer.write "AT+CFREQBANDMASK=" + mask + "\r\n"
    print "LoRaWAN Freqbandmask set"
    
  // Sets the work mode
  M5_setWorkMode mode:
    writer := Writer loraModule
    writer.write "AT+CWORKMODE=$(mode)\r\n"
    print "Work mode set"
  
  // Joins the Node
  M5_startJoin:
    writer := Writer loraModule
    writer.write "AT+CJOIN=1,0,60,8\r\n"
    print "Joining node call sent"
  
  M5_sendMSG confirm nbtrials data:
    encodedData := dec_to_hex data
    command := "AT+DTRX=" + "$(confirm)" + "," + "$(nbtrials)" + "," + "$(encodedData.size)" + "," + encodedData + "\r\n"
    print "Sending message: $(command)"
    writer := Writer loraModule
    writer.write command
