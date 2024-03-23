import base64
import mysql.connector
from mysql.connector import errorcode
import sys
import paho.mqtt.client as mqtt
import json
from datetime import datetime

mysqlConnected    = False
mysql_username    = ""
mysql_password    = ""
mysql_host_ip     = ""
mysql_socket_path = ""
sqlFile = open("iotstormdrain.sql").read()

try:
    if len(sys.argv) < 5:
        print ("Not enough arguments was given.")
        print ("Example usage: python MQTT_DB_Connector [Database name] [mysqlusername] [mysqlpassword] [host-ip] [mysql-socket-path]")
        sys.exit(-1)
    else:
        DB_NAME = sys.argv[1]
        mysql_username = sys.argv[2]
        mysql_password = sys.argv[3]
        mysql_host_ip  = sys.argv[4]
        mysql_socket_path = sys.argv[5]

        userChoice = ""
        while userChoice != 'y' and userChoice != 'n':
            userChoice = input("Connect to TTN (The Things Network) Network? (y/n) ").lower()
            if userChoice == 'y':
                print("Yes")
        
        if userChoice == "y":
            region = input("Please input which region you are based in. ")  # The region the user is using
        
        connectIP = input("Enter the address to the MQTT connection. ")
        connectPort = int(input("Enter the port for the connection. "))

        mqttUsername = input("Enter MQTT-connection username. ")
        mqttPassword = input("Enter MQTT-connection password. ")

except Exception as err:
    print(err)

cnx = mysql.connector.connect(user = mysql_username,
                              password = mysql_password,
                              host = mysql_host_ip,
                              unix_socket = mysql_socket_path,
                              )
cursor = cnx.cursor()
	    
# Credentials for the MQTT Connection
User = mqttUsername      
Password = mqttPassword


# This function creates the database
def create_database(cursor, DB_NAME):
    try:
        cursor.execute(
            "CREATE DATABASE {} DEFAULT CHARACTER SET 'utf8'".format(DB_NAME))
    except mysql.connector.Error as err:
        print("Failed creating database: {}".format(err))
        exit(1)

# Try to use the Database, and if it does not exist it shall create one with the name 'DB_NAME'
try:
    cursor.execute("USE {}".format(DB_NAME))
    print("Database '{}' already installed".format(DB_NAME))
except mysql.connector.Error as error:
    print("Database {} does not exist.".format(DB_NAME))           # If the database does not exist, we create it and fill it with the sql dump data
    if error.errno == errorcode.ER_BAD_DB_ERROR:
        create_database(cursor, DB_NAME)
        print("Database {} created successfully.".format(DB_NAME))
        cnx.database = DB_NAME

        for result in cursor.execute(sqlFile, multi=True):
            if result.with_rows:
                print("Rows produced by statement '{}':".format(result.statement))
                print(result.fetchall())
            else:
                print("Number of rows affected by statement '{}': {}".format(result.statement, result.rowcount))

# SQL command lines to insert data into specific tables
insert_logs_table = "INSERT INTO waterlogs (date, device_id, app_id, frm_payload, rssi, snr)"
insert_temp_table = "INSERT INTO templogs (date, device_id, app_id, temperature, rssi, snr)"
insert_humidity_table = "INSERT INTO humiditylogs (date, device_id, app_id, humidity, rssi, snr)"
insert_bat_table =  "INSERT INTO batlogs (date, device_id, app_id, bat_lvl, rssi, snr)"

# This function inserts the insert_str (a long string filled with insert and values) into the tables
def insert_into_table(cursor, insertTable, values):
    insert_sql = insertTable + " " + values

    try:
        print("SQL query {}: ".format(insert_sql), end='')
        cursor.execute(insert_sql)
    except mysql.connector.Error as err:
        print(err.msg)
    else:
        # Make sure data is committed to the database
        cnx.commit()
        print("OK")


# Write the uplink message into the Database
def saveToDB(someJSON):
  end_device_ids = someJSON["end_device_ids"]
  device_id = end_device_ids["device_id"]
  application_id = end_device_ids["application_ids"]["application_id"]

  try:
    uplink_message = someJSON["uplink_message"];
    frm_payload = uplink_message["frm_payload"];
    rssi = uplink_message["rx_metadata"][0]["rssi"];
    snr = uplink_message["rx_metadata"][0]["snr"];
    frm_payload = base64.b64decode(frm_payload).hex()

    payload_dec = int(bin(int(frm_payload, 16)), 2) # Decoding the Hexadecimal payload into decmial
      
    now = datetime.now()
    dataValues = "Values('%s','%s','%s','%s','%s',%d)" % (now, device_id, application_id, int(str(payload_dec)[1:len(str(payload_dec))]), rssi, snr)
    print ("\n\n" + dataValues)
    
    if int(str(payload_dec)[0]) == 1:
        insert_into_table(cursor, insert_logs_table, dataValues)
    elif int(str(payload_dec)[0]) == 2:
        insert_into_table(cursor, insert_temp_table, dataValues)
    elif int(str(payload_dec)[0]) == 3:
        insert_into_table(cursor, insert_humidity_table, dataValues)
    elif int(str(payload_dec)[0]) == 4:
        insert_into_table(cursor, insert_bat_table, dataValues)
        
  except Exception as err:
     print (err)  

# MQTT event function
def on_message(mqttc, obj, msg):
    print("\nMessage: " + msg.topic + " " + str(msg.qos))
    parsedJSON = json.loads(msg.payload)
    saveToDB(parsedJSON)

print("Initializing the MQTT Client")
mqttc = mqtt.Client(mqtt.CallbackAPIVersion.VERSION1)

print("Assigning callback functions")
mqttc.on_message = on_message

print("Connecting..")

# Setup authentication from settings above
mqttc.username_pw_set(User, Password)

# Enabling encryption of the messaging.
mqttc.tls_set()	# default certification authority of the system

mqttc.connect(region + connectIP,  connectPort, 60)
mqttc.subscribe("#", 0)	# Subscribe to all device uplinks (all topics).

try:    
  run = True
  print("Connected to and listening to the MQTT Connection..")
  while run:
    mqttc.loop(10) 	# timeout
    print(".", end="", flush=True)	# feedback to the user that something is actually happening
    
    
except KeyboardInterrupt:
    print("Exiting")
    cursor.close()
    cnx.close()
    sys.exit(0)