import gpio
import uart

main:
  task:: task-1
  task:: task-2
  task:: task-3

  print "\n\n---------------- Tasks ----------------\n"

task-1:
  timeStart := Time.now
  print "Task 1 started at: $(timeStart)\n"
  while true:
    print "Task 1 has been running for: $(timeStart.to_now)\n"
    sleep --ms=2000

task-2:
  while true:
    time := Time.now.local
    print "Task 2, current Time: \t $(%02d time.h):$(%02d time.m):$(%02d time.s)\n"
    sleep --ms=5000

task-3:
  while true:
    rndNbr := random 10000
    print "Task 3's Generated Number: $(rndNbr)\n"
    sleep --ms=2000