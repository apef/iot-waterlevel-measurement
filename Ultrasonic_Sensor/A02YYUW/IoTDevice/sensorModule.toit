import dyp_a01 show DYP_A01
import gpio

class sensorModule:
  sensorValue := 0
  sensor := null

  constructor tx_/int rx_/int:
    // tx := gpio.Pin tx_
    // rx := gpio.Pin rx_
    sensor = DYP_A01
      // --tx_pin=tx
      --rx_pin=rx_//17//18

  start:
    task::sensor_read
    
   
  sensor_read:
    print "Sensor reading started."
    while true:
      sensorValue = sensor.range
    sensor.off

  get_sensorValue -> int:
    return sensorValue