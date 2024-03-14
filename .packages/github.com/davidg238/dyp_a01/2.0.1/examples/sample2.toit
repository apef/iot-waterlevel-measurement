// Copyright 2024 Ekorau LLC
import ntp
import esp32
import device

import dyp-a01 show DYP-A01

main:

  set-time-from-net

  dyp := DYP-A01
    --tx-pin=22
    --rx-pin=21

  while true:
    print "{\"device\": $(device.hardware-id), \"time\": $(Time.now.local) ,\"range\": $(dyp.range)}"
    sleep --ms=15000

  dyp.off

set-time-from-net:
  set-timezone "MST7"  // Set as appropriate.
  now := Time.now.utc
  if now.year < 1981:
    result ::= ntp.synchronize
    if result:
      esp32.adjust-real-time-clock result.adjustment
      print "Set time to $Time.now by adjusting $result.adjustment"
    else:
      print "ntp: synchronization request failed"