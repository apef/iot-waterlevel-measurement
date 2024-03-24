import system.services
import dyp_a01 show DYP_A01
import dhtxx
import gpio
import dartino_regexp.regexp show RegExp

// Interface for the service, specifies for example which ID the service has (which is then used to find and install the service)
interface EnvironmentSensorService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="dd9eb2ef-a5e9-464e-b2ef-92ea02bf15ca"
      --major=1
      --minor=0

  temp -> float
  static temp-INDEX ::= 0 // Index values are used to differentiate which functionality was requested of the service.

  humidity -> float
  static humidity-INDEX ::= 1

// The service client is used to handle the requests that are given to the serviceprovider. As a mediator.
class EnvironmentSensorServiceClient extends services.ServiceClient implements EnvironmentSensorService:
  static SELECTOR ::= EnvironmentSensorService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  temp -> float:
    return invoke_ EnvironmentSensorService.temp-INDEX null
  
  humidity -> float:
    return invoke_ EnvironmentSensorService.humidity-INDEX null

// The service provider implements the functions defined in the interface, and returns their values
// when prompted by the client.
class EnvironmentSensorServiceProvider extends services.ServiceProvider
    implements EnvironmentSensorService services.ServiceHandler:

  temp-last_ := 0.0 // The last measured temperature
  hum-last   := 0.0 // The last measured humidity

  constructor:
    super "temp-sensor" --major=1 --minor=0
    provides EnvironmentSensorService.SELECTOR --handler=this
  
  // The handle function uses the index values to return the corresponding functionality that was requested
  handle index/int arguments/any --gid/int --client/int -> any:
    if index == EnvironmentSensorService.temp-INDEX: return temp
    if index == EnvironmentSensorService.humidity-INDEX: return humidity
    unreachable

  temp -> float:
    if temp-last_ == null:
      return -1.0 // If something went wrong, return -1
    else:
      return temp-last_

  humidity -> float:
    if hum-last == null:
      return -1.0
    else:
      return hum-last

  run --adc_pin/int -> none: // The main function for this application, will run while the device is awake
    pin := gpio.Pin adc_pin
    driver := dhtxx.Dht11 pin

    while true:
      data := driver.read_data_
      temp := driver.parse_temperature_ data
      hum  := driver.parse_humidity_ data

      temp-last_ = temp
      hum-last = hum
      