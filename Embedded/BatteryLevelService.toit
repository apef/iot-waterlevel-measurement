import system.services
import dyp_a01 show DYP_A01
import gpio
import gpio.adc

// ------------------------------------------------------------------

interface BatteryLevelService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="5fd1dd9e-a5e9-464e-b2ef-15ea02ca92bf"
      --major=1
      --minor=0

  batlvl -> int
  static batlvl-INDEX ::= 0

// ------------------------------------------------------------------

class BatteryLevelServiceClient extends services.ServiceClient implements BatteryLevelService:
  static SELECTOR ::= BatteryLevelService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  batlvl -> int:
    return invoke_ BatteryLevelService.batlvl-INDEX null

// ------------------------------------------------------------------

class BatteryLevelServiceProvider extends services.ServiceProvider
    implements BatteryLevelService services.ServiceHandler:

  batlvl-last_ := 0 // The last measured battery level distance

  constructor:
    super "batlvl-sensor" --major=1 --minor=0
    provides BatteryLevelService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == BatteryLevelService.batlvl-INDEX: return batlvl
    unreachable

  batlvl -> int:
    if batlvl-last_ == null:
      return -1
    else:
      if batlvl-last_ < 1:
        return 0
      else:
        return batlvl-last_

  run --adc-pin -> none:
      batpin := gpio.Pin adc-pin
      adc := adc.Adc batpin
      bat_percentage := 0
      while true:
        value := 0
        5.repeat: value += (mapFromTo adc.get 0.56 1.31 0.0 100.0); sleep --ms=2000//1.8 3.1 0.0 100.0); sleep --ms=2000
        bat_percentage = value/5
        batlvl-last_ = bat-percentage.to-int
        sleep --ms=1000
    
  mapFromTo x/float in_from/float in_to/float out_from/float out_to/float:
    slope := (out_to - out_from) / (in_to - in_from)
    y := out_from + slope * (x - in_from)
    return y
    