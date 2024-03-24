# iot-waterlevel-measurement

Project members: Simon Mira Engström, Andreas Axelsson

A project aimed at creating an IoT solution that will measure the water level in stormdrains. 

By measuring the water level in storm drains, it would be possible to:

* Know if the storm drains are not being drained correctly, which might indicate blockage.
* Make an overview over a series of connected stormdrains and be able to find out if there is a leak in the piping between stormdrains.
* Being able to see how the water level looks like on each day and storing it could provide useful data.

## Software
### Requirements
* Python 3.x
* Jaguar (TOIT)
* A MySQL DBMS (Database Management System)
<hr>

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

#### Python
In this project we use a python script to log the uplinks that are recieved from LoRaWAN. It is therefore neccessary that python is installed prior to running the script. 

You can follow this link to find the downloads for the python installation files: https://www.python.org/downloads/

After python has been installed, you need to install some required libraries in order to run the script.

1. Paho-mqtt. Install Paho-mqtt by using pip, open your commandline/terminal and issue this command: ``pip install paho-mqtt``. It might be possible that your pip installation is different, if the prior command does not work try: ```pip3 install paho-mqtt``.
2. Mysql connector. Install the mysql connector by issuing this command in your commandline/terminal: ```pip install mysql.connector-python```alternativly ``pip3 install mysql.connector-python``

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
This project uses a regular Power Bank for powering the components which connects trhough the microcontrollers micro USB port. But it is posible to use for example a Lipo battery and measure its battery level though the GPIO35 pin on the ESP32 board, were there is a battery level measure implemented in our code for that pin.

### Wiring diagrams
<img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/Waterlevel_improved_v2_bb.png?raw=true" width="400"> <img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/Waterlevel_improved_schem.png?raw=true" width="600">

### Battery measuring diagrams
These images below is an example on how we would measure the battery level from an Lipo battery to an analog pin on the ESP32 board. This was not used since a 3.7 volt battery was not enough to power all of our components in our project, it was therefore left out from the main images above.

<img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/batterylevel_bb.png?raw=true" width="600"> <img src="https://github.com/apef/iot-waterlevel-measurement/blob/main/img/batterylevel_schem.png?raw=true" width="400">


## How to run
Clone the repository to a desired location. (example using the terminal in a desired location: ``git clone https://github.com/apef/iot-waterlevel-measurement.git``)
### IoT Device
1. If the hardware is assembled according to the hardware setup, then proceed with connecting the microcontroller to your system with USB.
2. Enter the folder "Embedded" within the repository you cloned down locally and open up a terminal within it.
3. If you want to only test the device with running the code temporarily (which will be wiped when the device enters deep-sleep, or power source is removed) simply run issue the command: ``jag run main.toit``
4. If you want to install the application onto your device, then issue this command in the terminal instead: ``jag container install <name> main.toit`` where "name" is what you want to name the application.
5. If the device is running the application (either temporarily or as an installed container) it is possible, if connected to your system with USB, to monitor the device with: ``jag monitor`` however, if the code is running temporarily and is not installed, then it is best to issue the monitor command prior to running the code. It is possible to monitor while the device is operating the code temporarily with ``jag monitor --attach`` however it may sometimes restart the device.

It is not neccessary for the device to be inserted into an USB port when doing the above setup. The code is able to be installed and or run temporarily on the device by transmitting it wirelessly. The downside is that monitoring the device (except the output that is recieved in your LoRaWAN platform) is only possible through the USB connection. Otherwise, if the software setup was done correctly and the device was given the credentials to an interne connection (WiFi) then simply connect to the same network and issue the commands above. As long as the device has a power source it will connect to the internet connection and be ready for receiving code.

### Python script
1. Enter the folder "Database" within the repository that you cloned down locally and open up a terminal within it.
2. Run the python script with issuing the command ``python MQTT_DB_Connector.py <database-name> <mysql-username> <mysql-password> <mysql-host-address> <file address to mysql unix-socket``.
    - Database-name is the name of the database, if it does not exist the python script will create a new database with the given name.
    - MySQL username is the username that is set for the database user that shall connect to the database. This means that the user must exist prior to running the script. Example of this would be the default "root" user, if not changed.
    - MySQL password is the password for the user specified above, an example of this would be the default "root" password if it has not been changed for the root user.
    - MySQL host address is the IP address which the MySQL instance is hosted upon, for example if run locally it could be "localhost"/"127.0.0.1 as default.
    - MySQL unix-socket is the file address (the string that specifies where the file exists on your system) to the socket in which the communication to the MySQL server is going to be run through. As the authors of this project used the software "MAMP" their unix-socket address by default was: "/Applications/MAMP/tmp/mysql/mysql.sock"
3. If the command was entered with correct amount of arguments you should be presented with prompt asking if you're going to connect to The Things network (TTN). Enter Yes or No.
4. If Yes, then you need to specify which region you are going to connect from, read the documentation from The Things Network: https://www.thethingsindustries.com/docs/reference/ttn/addresses/
5. Specify the host address that you are going to connect to, however you need to add "." at the beginning of the address if connecting to TTN as per the example: https://eu1.cloud.thethings.network/.
6. Enter the port that the connection you are going to connect to uses.
7. Enter the username for the MQTT server you are connecting to, this means the 'address' to the server. An example from TTN would be: mymqttserver@ttn
8. Enter the password for the MQTT server you are connecting to.

If the above steps were done without issue, the python script should now be listening to the incoming MQTT messages.
