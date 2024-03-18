// import gpio show Pin
import system.services
import dyp_a01 show DYP_A01
import dhtxx
import gpio
import dartino_regexp.regexp show RegExp


// ------------------------------------------------------------------

interface EnvironmentSensorService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="dd9eb2ef-a5e9-464e-b2ef-92bf15ea02ca"
      --major=1
      --minor=0

  temp -> int
  static temp-INDEX ::= 0

  humidity -> float
  static humidity-INDEX ::= 1

// ------------------------------------------------------------------

class EnvironmentSensorServiceClient extends services.ServiceClient implements EnvironmentSensorService:
  static SELECTOR ::= EnvironmentSensorService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  temp -> float:
    return invoke_ EnvironmentSensorService.temp-INDEX null
  
  humidity -> float:
    return invoke_ EnvironmentSensorService.humidity-INDEX null

// ------------------------------------------------------------------

class EnvironmentSensorServiceProvider extends services.ServiceProvider
    implements EnvironmentSensorService services.ServiceHandler:

  temp-last_ := 0 // The last measured temperature
  hum-last   := 0 // The last measured humidity

  constructor:
    super "temp-sensor" --major=1 --minor=0
    provides EnvironmentSensorService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == EnvironmentSensorService.temp-INDEX: return temp
    unreachable

  temp -> float:
    if temp-last_ == null:
      return -1.0
    else:
      return temp-last_

  humidity -> float:
    if hum-last == null:
      return -1.0
    else:
      return hum-last

  run --adc_pin/int -> none:
    pin := gpio.Pin adc_pin
    driver := dhtxx.Dht11 pin

    while true:
      data := driver.read_data_

      temp := driver.parse_temperature_ data
      hum  := driver.parse_humidity_ data

      temp-last_ = temp
      hum-last = hum
      