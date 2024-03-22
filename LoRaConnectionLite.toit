import gpio show Pin
import system.services
// import dyp_a01 show DYP_A01
import reader show BufferedReader
import writer show Writer
import uart show Port
import dartino_regexp.regexp show RegExp
import .dec_to_hex
import math show pow

// ------------------------------------------------------------------

interface LoraConnectionService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="36989d64-baad-4f06-90A8-fcf796a287c1"
      --major=1
      --minor=0

  sendMSG data/int -> bool
  static sendMSG-INDEX ::= 0

// ------------------------------------------------------------------

class LoraConnectionServiceClient extends services.ServiceClient implements LoraConnectionService:
  static SELECTOR ::= LoraConnectionService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  sendMSG data/int -> bool:
    return invoke_ LoraConnectionService.sendMSG-INDEX data

// ------------------------------------------------------------------

class LoraConnectionServiceProvider extends services.ServiceProvider
    implements LoraConnectionService services.ServiceHandler:

  range-last_ := 0
  loraModule := null
  isconnected := false
  device_eui := ""
  app_eui := ""
  app_key := ""
  join_eui := "0000000000000000"
  freq_mask := "0001"
  RxWindow := "869525000"
  spreadFactor := "9"
  ul_dl_mode := "2"

  constructor:
    super "range-sensor" --major=1 --minor=0
    provides LoraConnectionService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == LoraConnectionService.sendMSG-INDEX: return sendMSG arguments
    unreachable
  
  sendMSG data/int -> bool:
    print "Got Request to send: $(data)"
    confirm := 1
    nbtrials := 8
    // if 
    encodedData := dec_to_hex data
    strData := "$(encodedData)"
    command := "AT+DTRX=" + "$(confirm)" + "," + "$(nbtrials)" + "," + "$(strData.size)" + "," + strData + "\r\n"
    print "Sending command: $(command)"
    response := waitMSG command 10000
    re := RegExp "\nOK\n"
    check := re.has_matching response

    if check:
      return true
    else:
      return false

  run tx_pin/int rx_pin/int device_eui_/string app_eui_/string app_key_/string -> none:
    tx := Pin tx_pin
    rx := Pin rx_pin
    loraModule = Port --rx=rx --baud-rate=115200 --tx=tx

    device_eui = device_eui_
    app_eui = app_eui_
    app_key = app_key_

    task:: checkDeviceConnect
    
    while not isconnected:
      sleep --ms=100
    
    // task:: readLora 
      
    writer := Writer loraModule
  
    writer.write "AT+CJOINMODE=0\r\n"
    sleep --ms=50
    writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPKEY=" + app_key + "\r\n"
    // writer.write "AT+CULDLMODE=" + ul_dl_mode + "\r\n"
    sleep --ms=50


    sleep --ms=1000
    writer.write "AT+CSAVE\r\n"
    sleep --ms=10000

    writer.write "AT+CJOIN=1,0,60,8\r\n"

  checkDeviceConnect:
    response := ""
    writer := Writer loraModule
    check := false
    
    try:
      response = waitMSG "AT+CGMI?\r\n" 5000
      sleep --ms=6000
  
      re := RegExp "\nOK\n"
      check = re.has_matching response
  
    finally:
      if check:
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
          break
        
        if line == "FAIL":
          break
  
      if (timeStart.to-now.in-ms > waitTime):
        break
    return response
  
  
  readLora:
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