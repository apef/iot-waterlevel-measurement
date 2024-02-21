import dyp_a01 show DYP_A01

main:
  print "Sensor reading activated.."
  dyp := DYP_A01
    //--tx_pin=17
    --rx_pin=17

  while true:
    sleep --ms=1000  
    msg := "{\"range\": $(dyp.range)}"
    print msg

  dyp.off