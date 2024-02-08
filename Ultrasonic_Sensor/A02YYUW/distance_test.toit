// New revised code to read from the A02YYUW sensor, after consulting the TOIT discord for help with port.read blocking
// the code from continuing execution.

import gpio
import uart

main:
  rx := gpio.Pin 17  // Labeled as TX on the sensor.
  port := uart.Port --rx=rx --baud-rate=9600 --tx=null

  while true:
    data := port.read
    print "received: $data"