import gpio
import uart
import writer show Writer
import reader show BufferedReader

// main: 
//   // loraModule := uart.Port --baud_rate=115200 --tx=gpio.Pin 1 --rx=gpio.Pin 3
//   port := uart.Port --rx=rx --baud-rate=9600 --tx=null

//     task:: readLora loraModule

main:
  tx := gpio.Pin 1
  rx := gpio.Pin 3  // Labeled as TX on the sensor.
  loraModule := uart.Port --rx=rx --baud-rate=115200 --tx=null

  print "Prior to function"
  task:: readLora loraModule
  // while true:
  //   data := port.read
  //   print "received: $data"

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

writeLora loraModule textString:
  print "Writing $(textString) to LoRa Module.."
  isDone := false
  task::

      while not isDone:

        isDone = true
        