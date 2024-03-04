import base64
b = "7g=="

b2 = base64.b64decode(b).hex()#.decode("ISO-8859-1")
print(b2, type(b2))