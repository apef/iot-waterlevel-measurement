// Is used to convert decimal numbers into hexadecimal numbers: Ex. 222 -> DE
dec_to_hex decVal:
  decVal = decVal.to-int
  lst := []
  retString := "" 
  while not decVal == 0:
    temp := 0
    charVal := ""
    temp = decVal % 16  // Modulus operation to retrieve the remainer after division

    if temp < 10:       
      charVal = to_char temp+48 // if value is between 0-9 add 48 to get the ASCII value for the number
    else:
      charVal = to_char temp+55 // Add 55 to get the ASCII value (ex: 15 + 55 = 70 --> F)
    
    lst.add charVal

    decVal = decVal / 16

  start := lst.size
  start--
  for i := start; i > -1; i-=1: // As the numbers are in reverse order, we go through the list backwards
    retString += lst[i]         // Append each number into the string that shall be returned.
  return retString

to_char value -> string:
  chrLst := ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]

  // Subtract the value down to get the corresponding index in the chrLst
  // ex: 9 = 57, 57 - 48 = 9 which also corresponds to the 9th array index
  if value > 47 and value < 58:
    value = value - 48
  
  // If the value is between 9 and 16 (10 = (10+55), 16=(16+55)) proceed with same operation as above
  else if value > 64 and value < 71:
    value = value - 55

  else:
    return ""
  
  return chrLst[value]