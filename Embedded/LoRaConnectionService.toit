import gpio show Pin
import system.services
import reader show BufferedReader
import writer show Writer
import uart show Port
import dartino_regexp.regexp show RegExp
import .dec_to_hex

interface LoraConnectionService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="36989d64-baad-4f06-90A8-fcf796a287c1"
      --major=1
      --minor=0

  sendMSG data/int -> bool
  static sendMSG-INDEX ::= 0

class LoraConnectionServiceClient extends services.ServiceClient implements LoraConnectionService:
  static SELECTOR ::= LoraConnectionService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  sendMSG data/int -> bool:
    return invoke_ LoraConnectionService.sendMSG-INDEX data

class LoraConnectionServiceProvider extends services.ServiceProvider
    implements LoraConnectionService services.ServiceHandler:

  loraModule := null
  isconnected := false
  device_eui := ""
  app_eui := ""
  app_key := ""
  join_eui := "0000000000000000"
  freq_mask := "0001"     
  RxWindow := "869525000"
  spreadFactor := "9"
  
  constructor:
    super "lora-module" --major=1 --minor=0
    provides LoraConnectionService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == LoraConnectionService.sendMSG-INDEX: return sendMSG arguments
    unreachable
  
  // Sends data through the LoRaWAN connection.
  sendMSG data/int -> bool:
    print "Got Request to send: $(data)"
    confirm := 1                    // Confirm transmission of data
    nbtrials := 8                   // Amount of retries before abandoning the transmission
    encodedData := dec_to_hex data  // Encodes the data into hexadecimal
    strData := "$(encodedData)"     // Cast the encoded bytes into a string (it is then able to retrieve the length)
    command := "AT+DTRX=" + "$(confirm)" + "," + "$(nbtrials)" + "," + "$(strData.size)" + "," + strData + "\r\n"
    
    response := waitMSG command 10000

    re := RegExp "\nOK\n"           // Find if the pattern which confirms a successful transmission was recieved
    check := re.has_matching response

    if check:
      return true
    else:
      return false

  run tx_pin/int rx_pin/int device_eui_/string app_eui_/string app_key_/string -> none:
    tx := Pin tx_pin
    rx := Pin rx_pin
    loraModule = Port --rx=rx --baud-rate=115200 --tx=tx    // Assign the serial port connection

    device_eui = device_eui_
    app_eui = app_eui_
    app_key = app_key_

    task:: checkDeviceConnect  // Start checking that the module is connected in a separate task
                               // as to not block the rest of the code.
    while not isconnected:
      sleep --ms=100
       
    writer := Writer loraModule
  
    writer.write "AT+CJOINMODE=0\r\n"
    sleep --ms=50             // Sleeps to ensure that the configuration commands are set
    writer.write "AT+CDEVEUI=" + device-eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPEUI=" + app_eui + "\r\n"
    sleep --ms=50
    writer.write "AT+CAPPKEY=" + app_key + "\r\n"
    sleep --ms=50

    writer.write "AT+CSAVE\r\n"           // Save the configuration
    sleep --ms=1000

    writer.write "AT+CJOIN=1,0,60,8\r\n"  // Try to join the network

  checkDeviceConnect:
    response := ""
    writer := Writer loraModule
    check := false
    
    try:
      response = waitMSG "AT+CGMI?\r\n" 5000  // Ask the device for its name, an answer will show that it is connected
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

    // Start a timer when awaiting the response, cancel if the timer runs out
    while true:
      if (timeStart.to-now.in-ms < waitTime):
        line := reader.read-line
        response += line + "\n"
  
        if line == "OK":
          break
        
        if line == "FAIL":
          break
      else:
        break
    return response