import gpio

TRIGGER ::= 33
ECHO ::= 32

main:
  // print "Running"
  trigger := gpio.Pin TRIGGER --output
  echo := gpio.Pin ECHO --input

  // while true: 
  //   print"Running"
  //   sleep --ms=1000
  while true:
    print "measured $(measure-distance trigger echo)cm"
    sleep --ms=500

measure-distance trigger echo:
  trigger-start := Time.monotonic-us
  trigger.set 1
  while Time.monotonic-us < trigger-start + 10:
    // Do nothing while waiting for the 10us.
  trigger.set 0

  while echo.get != 1: null
  echo-start := Time.monotonic-us
  while echo.get == 1: null
  echo-end := Time.monotonic-us
  diff := echo-end - echo-start
  return diff / 58
