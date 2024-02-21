import dhtxx
import gpio

GPIO_PIN_NUM ::= 22

main:
  pin := gpio.Pin GPIO_PIN_NUM
  driver := dhtxx.Dht11 pin

  (Duration --s=1).periodic:
    print driver.read