import .TOIT_RFM95Driver

main:
  print "LoRa driver"
  sleep --ms=1000
  spi := spi.Bus
    --mosi=gpio.Pin 27  // MOSI
    --miso=gpio.Pin 19  // MISO
    --clock=gpio.Pin 5 //14  // Clock

  device := spi.device
    --cs=gpio.Pin 18
    --frequency=8_000_000

  lora := RFM95
    device
    gpio.Pin 26  // DI00 (interrupt?)

  // task::
  //   while true:
      // print "read '$(lora.read.to_string)'"

  // i := 0
  // while true:
  //   i++
  //   print "[$Time.monotonic_us] sending now"
  //   lora.write "hello world $i".to_byte_array
  //   print "[$Time.monotonic_us] done sending"
  //   sleep --ms=1000