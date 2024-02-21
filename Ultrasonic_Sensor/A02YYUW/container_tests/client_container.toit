import esp32

main:
  print "Clinent started.."
  sleep --ms=10000
  esp32.deep-sleep (Duration --s=5)