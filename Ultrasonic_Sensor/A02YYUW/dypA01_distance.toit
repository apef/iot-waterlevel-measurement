// Copyright 2021 Ekorau LLC

import dyp_a01 show DYP_A01

main:

  dyp := DYP_A01
    //--tx_pin=17
    --rx_pin=17

  while true:
    msg := "{\"range\": $(dyp.range)}"
    print msg

  dyp.off