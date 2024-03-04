// New revised code to read from the A02YYUW sensor, after consulting the TOIT discord for help with port.read blocking
// the code from continuing execution.

import gpio
import uart

main:
  rx := gpio.Pin 18  // Labeled as TX on the sensor.
  tx := gpio.Pin 17
  // port := uart.Port --rx=rx --baud-rate=9600 --tx=null
  port := uart.Port --rx=rx --baud-rate=115200 --tx=tx

  print "Test"
  while true:
    data := port.read
    print "received: $data"
