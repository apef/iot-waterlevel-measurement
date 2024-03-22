/**
* How to connect the pins to read serial input
* from the waterproof ultrasonic sensor A02YYUW.
*  _______________                                 _________
* |               | 3v3 --------------------- VCC |         |
* | Heltec WSL V3 | GND --------------------- GND | A02YYUW |
* |               | U1TXD (GPIO17)            RX  |         |
* |_______________| U1RXD (GPIO18) ---------- TX  |_________|
*/

import dyp_a01 show DYP_A01

main:

  dyp := DYP_A01
    --tx_pin=4
    --rx_pin=3//17//18

  while true:
    msg := "Distance: $(dyp.range) mm"
    print msg

  dyp.off