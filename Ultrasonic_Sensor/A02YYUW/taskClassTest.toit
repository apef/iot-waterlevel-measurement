class M5LoRaDevice:
  isconnected := false
  sensorValue := 0

  

  start:
    
    task::checkConnectTest

    while not isconnected:
      sleep --ms=100

    print "Works"

  checkConnectTest:
    5.repeat:
      print "Task: Repeating"
      sleep --ms=500
    print "Task: Setting to true"
    isconnected = true

main:
  dev := M5LoRaDevice
  dev.start