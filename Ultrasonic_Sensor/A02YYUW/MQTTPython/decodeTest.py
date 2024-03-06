import base64
b = "7g=="

b2 = base64.b64decode(b).hex()#.decode("ISO-8859-1")
print(b2, type(b2))


now = "2024"
device_id = "testid"
application_id = "appid"
frm_payload = "ee"
rssi = "rsi"
snr = 4.2

dataValues = "Values('%s','%s','%s','%s','%s',%d)" % (now, device_id, application_id, frm_payload, rssi, snr)

print (dataValues)