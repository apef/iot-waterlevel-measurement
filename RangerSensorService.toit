// import gpio show Pin
import system.services
import dyp_a01 show DYP_A01


// ------------------------------------------------------------------

interface RangeSensorService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="dd9e5fd1-a5e9-464e-b2ef-92bf15ea02ca"
      --major=1
      --minor=0

  range -> int
  static RANGE-INDEX ::= 0

// ------------------------------------------------------------------

class RangeSensorServiceClient extends services.ServiceClient implements RangeSensorService:
  static SELECTOR ::= RangeSensorService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  range -> int:
    return invoke_ RangeSensorService.RANGE-INDEX null

// ------------------------------------------------------------------

class RangeSensorServiceProvider extends services.ServiceProvider
    implements RangeSensorService services.ServiceHandler:

  range-last_ := 0 // The last measured distance

  // The full distance from the devices location down to the limit. For example, if place on a bridge
  // it's the distance down to the seabed.
  referenceDistance := 0  

  constructor:
    super "range-sensor" --major=1 --minor=0
    provides RangeSensorService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == RangeSensorService.RANGE-INDEX: return range
    unreachable

  range -> int:
    if range-last_ == null:
      return -1
    else:
      return range-last_

  waterlevelCalc distance/int -> int:
    return referenceDistance - distance

  run --tx/int --rx/int --refDistance/int -> none:
    referenceDistance = refDistance
    sensor := DYP_A01
        --tx-pin=tx //not used
        --rx-pin=rx
    while true:
      range-last_ = waterlevelCalc sensor.range
      // print range-last_
    sensor.off