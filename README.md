# iot-waterlevel-measurement

Project members: Simon Mira Engström, Andreas Axelsson

A project aimed at creating an IoT solution that will measure the water level in stormdrains. 

By measuring the water level in storm drains, it would be possible to:

* Know if the storm drains are not being drained correctly, which might indicate blockage.
* Make an overview over a series of connected stormdrains and be able to find out if there is a leak in the piping between stormdrains.
* Being able to see how the water level looks like on each day and storing it could provide useful data.

## Hardware
### Microcontroller (MCU)
This project uses a Wireless Stick Lite V3 from Heltec, which has BLE/WiFi/LoRa integrated. 

### Sensors
* Distance measuring: A02YYUW - Waterproof ultrasonic sensor
* Battery level measuring: MAX17048 Fuel cell Gauge

## Software
### TOIT Framework
The TOIT framework allows for remote flashing an ESP32 device, this means that the device that will be installed inside of stormdrains do not have to be removed from its location in order to update it via a serial connection.

### Software setup
#### TOIT
1. Install TOIT by downloading it from https://toitlang.org/
2. Connect the Microcontroller via USB and enter the command "jag flash" in your terminal/commandline
3. Insert the name of your WiFi-network and the password. The device will then be connected to WiFi and you can then upload TOIT applications wirelessly.


