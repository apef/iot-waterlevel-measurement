# Serial interface to DYP-A01 ultrasonic sensor

A simple serial interface to the inexpensive DYP-A01 ultrasonic ranger, available from Adafruit and AliExpress.

The sensor has a nominal 0.28-7.5m range, with a constrained sensing cone.
The interface implemented here is read-only, at 9600 baud (sensor reads may be triggered by pin3 RX, not implemented).

## Hardware tested
[Adafruit HUZZAH32 - ESP32 Feather Board](https://www.adafruit.com/product/3405)  
[DYP-A01 ultrasonic ranger](https://www.adafruit.com/product/4664)

## Connections
| DYP-A01 | HUZZAH32 ESP32 | Description | 
|:--------|:----------------:|:-----------|
| Pin 1, Vin, red | 3V  | 3v power from Huzzah |
| Pin 2, GND, black | GND | GND from Huzzah |
| Pin 3, RX, yellow  |  | sensor trigger, (not connected) |
| Pin 4, TX, white  | IO21, RX  | serial input to ESP32 |

## References

[User Manual of DYP-A01-V2.0](https://cdn-shop.adafruit.com/product-files/4664/4664_datasheet.pdf)
