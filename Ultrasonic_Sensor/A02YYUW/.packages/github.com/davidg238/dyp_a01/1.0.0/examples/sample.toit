// Copyright 2021 Ekorau LLC

import dyp_a01 show DYP_A01

main:

  dyp := DYP_A01
    --tx_pin=22
    --rx_pin=21

  msg := "{\"range\": $(dyp.range)}"
  print msg

  dyp.off
