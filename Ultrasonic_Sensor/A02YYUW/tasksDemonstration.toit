import dyp_a01 show DYP_A01

main:


  // task::sensor
  task::durationTask
  task::timeTask
  task::genTask


sensor:
  dyp := DYP_A01
    //--tx_pin=17
    --rx_pin=17
  while true:
    msg := "Sensor Distance: $(dyp.range) mm"
    print msg
    sleep --ms=1000

  dyp.off

durationTask:
  timeStart := Time.now
  print "Task 1 started at: $(timeStart)\n"
  while true:
    print "Task 1 has been running for: $(timeStart.to_now)\n"
    sleep --ms=2000

timeTask:
  while true:
    time := Time.now.local
    print "Task 2, current Time: \t $(%02d time.h):$(%02d time.m):$(%02d time.s)\n"
    sleep --ms=5000

genTask:
  while true:
    rndNbr := random 10000
    print "Task 3's Generated Number: $(rndNbr)\n"
    sleep --ms=2000