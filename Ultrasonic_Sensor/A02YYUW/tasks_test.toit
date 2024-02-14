import gpio
import uart

// The red LED is connected to pin 17.
LED1 ::= gpio.Pin.out 17
// The green LED is connected to pin 18.
LED2 ::= gpio.Pin.out 18

rx := gpio.Pin 17  // Labeled as TX on the sensor.
port := uart.Port --rx=rx --baud-rate=9600 --tx=null

main:
  // Note the double `::` on the next two lines.
  // Start a task that runs the my-task-1 function.
  task:: my-task-1 port
  // Start a second task that runs my-task-2.
  task:: my-task-2

my-task-1 theport:
  while true:
    data := theport.read
    print "received: $data"
  // while true:
  //   print "Task1"
  //   sleep --ms=500
    // LED1.set 1
    // sleep --ms=500
    // LED1.set 0

my-task-2:
  while true:
    print "Task2"
    sleep --ms=123
    // LED2.set 1
    // sleep --ms=123
    // LED2.set 0