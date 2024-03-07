import gpio.adc show Adc
import gpio

main:
  adc := Adc (gpio.Pin 4)
  bat_percentage := 0
  while true:
    // value := 0
    // 5.repeat: value += (mapFromTo adc.get 1.8 3.1 0.0 100.0); sleep --ms=2000
    // bat_percentage = value/5
    print "Battery: $(%.2f adc.get)%"//bat_percentage
    sleep --ms=1000

mapFromTo x/float in_from/float in_to/float out_from/float out_to/float:
  slope := (out_to - out_from) / (in_to - in_from)
  y := out_from + slope * (x - in_from)
  print "x: $x slope: $slope y: $y%"
  return y