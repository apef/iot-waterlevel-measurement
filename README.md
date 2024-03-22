# iot-waterlevel-measurement

Project members: Simon Mira Engström, Andreas Axelsson

A project aimed at creating an IoT solution that will measure the water level in stormdrains. 

By measuring the water level in storm drains, it would be possible to:

* Know if the storm drains are not being drained correctly, which might indicate blockage.
* Make an overview over a series of connected stormdrains and be able to find out if there is a leak in the piping between stormdrains.
* Being able to see how the water level looks like on each day and storing it could provide useful data.

## Hardware
### Microcontroller (MCU)
This project uses a DOIT ESP32 DEVKIT V1 board, which has Wi-Fi and Bluetooth intergrated.

### Sensors
This project uses the folowing two sensors
* Distance measuring: A02YYUW - Waterproof ultrasonic sensor
* Temperature and humidity measuring: DHT11

### LoRaWAN
This project uses a LoRaWAN Unit 868MHz from M5stack for LoRa connetion.

### Battery
This project uses a regular Power Bank for powering the components which connects trhough the microcontrollers micro USB port. But it is posible to use for example a Lipo battery and measure its battery level though the GPIO32 pin on the ESP32 board, were there is a battery level measure implemented in our code for that pin.

### Wiring diagram
<img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/Waterlevel_improved_bb.png?raw=true" width="400"> <img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/Waterlevel_improved_schem.png?raw=true" width="600">

## Software
### TOIT Framework
The TOIT framework allows for remote flashing an ESP32 device, this means that the device that will be installed inside of stormdrains do not have to be removed from its location in order to update it via a serial connection.

### Software setup
#### TOIT
1. Install Jaguar (the TOIT application for ESP32 devices) by choosing the operating system you are planning to use.
    <details>
      <summary>Windows</summary>
    
      If you are using a Windows operating system, you can download TOIT by running this command: ``winget install --id=Toit.Jaguar -e ``
    </details>

    <details>
      <summary>OSX (Mac)</summary>
    
      If you are using an OSX operating system, you can download TOIT by running this command: ``brew install toitlang/toit/jag``
    </details>

    <details>
      <summary>Linux</summary>
    
      If you are using a Linux operating system, you can download TOIT by running this command: ``yay install jaguar-bin``
    </details>

2. After installing Jaguar run the setup command: ``jag setup``
3. Connect the Microcontroller via USB and enter the command ``jag flash`` in your terminal/commandline
4. Insert the name of your WiFi-network and the password. The device will then be connected to WiFi and you can then upload TOIT applications wirelessly.

When the installation has been successful, it is then possible to monitor the device by using this command: ``jag monitor``
In the output from the device, it is possible to retrieve the IP address of the device. Ensure that you are on the same network as the device.

If the serial monitor displays that Jaguar is running correctly on the device, which can be seen by the output of its hosted website link, then you should scan for the device. 

Enter the command ``jag scan`` in your command terminal, this will scan for all currently running Jaguar devices on the same network. 

If the scan does not return any found Jaguar devices, despite the device running correctly and you've ensured that you're on the correct network, then you can scan for the device manually using: ``jag scan *device-ip*``

