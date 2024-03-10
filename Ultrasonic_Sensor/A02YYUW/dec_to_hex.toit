import encoding.hex

main:
  decVal := 5882
  hexVal := dec_to_hex decVal
  print hexVal

dec_to_hex decVal:
  lst := []
  retString := ""
  while not decVal == 0:
    temp := 0
    charVal := ""
    temp = decVal % 16

    if temp < 10:
      charVal = to_char temp+48
    else:
      charVal = to_char temp+55
    
    lst.add charVal

    decVal = decVal / 16

  start := lst.size
  start--
  for i := start; i > -1; i-=1:
    retString += lst[i]
  return retString

to_char value -> string:
  chrLst := ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]

  
  if value > 47 and value < 58:
    value = value - 48

  else if value > 64 and value < 71:
    value = value - 55

  else:
    return ""
  
  return chrLst[value]


  

  
