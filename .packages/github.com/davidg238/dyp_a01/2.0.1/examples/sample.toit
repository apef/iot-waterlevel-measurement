// Copyright 2021, 2024 Ekorau LLC

import dyp-a01 show DYP-A01

main:

  dyp := DYP-A01
    --tx-pin=22
    --rx-pin=21

  msg := "{\"range\": $(dyp.range)}"
  print msg

  dyp.off
