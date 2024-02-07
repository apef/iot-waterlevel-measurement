import gpio

TX ::= 17
RX ::= 16

main:
  // print "Running"
  UART_OUT := gpio.Pin TX --output
  UART_IN := gpio.Pin RX --input

  // while true: 
  //   print"Running"
  //   sleep --ms=1000
  while true:
    print "RX $(UART_IN.get) \n TX $(UART_OUT.get)"
    // print "measured $(measure-distance UART_OUT UART_IN)cm"
    sleep --ms=1000

// measure-distance UART_OUT UART_IN:

//   return 1