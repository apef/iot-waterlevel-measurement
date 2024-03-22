import system.services
import dyp_a01 show DYP_A01


// ------------------------------------------------------------------

interface DistanceSensorService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="dd9e5fd1-a5e9-464e-b2ef-15ea02ca92bf"
      --major=1
      --minor=0

  distance -> int
  static distance-INDEX ::= 0

// ------------------------------------------------------------------

class DistanceSensorServiceClient extends services.ServiceClient implements DistanceSensorService:
  static SELECTOR ::= DistanceSensorService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  distance -> int:
    return invoke_ DistanceSensorService.distance-INDEX null

// ------------------------------------------------------------------

class DistanceSensorServiceProvider extends services.ServiceProvider
    implements DistanceSensorService services.ServiceHandler:

  distance-last_ := 0 // The last measured distance

  // The full distance from the devices location down to the limit. For example, if place on a bridge
  // it's the distance down to the seabed.
  referenceDistance := 0  

  constructor:
    super "distance-sensor" --major=1 --minor=0
    provides DistanceSensorService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == DistanceSensorService.distance-INDEX: return distance
    unreachable

  distance -> int:
    if distance-last_ == null:
      return -1
    else:
      return distance-last_

  waterlevelCalc distance/int -> int:
    return referenceDistance - distance

  run --tx/int --rx/int --refDistance/int -> none:
    referenceDistance = refDistance
    sensor := DYP_A01
        --tx-pin=tx //not used
        --rx-pin=rx
    while true:
      distance-last_ = waterlevelCalc sensor.range
      // print distance-last_
    sensor.off