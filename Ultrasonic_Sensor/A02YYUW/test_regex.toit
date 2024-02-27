import dartino_regexp.regexp show RegExp
import expect show *



main: 
  re := RegExp "foo.*bar"
  check := re.has_matching "foo bar"

  re2 := RegExp "\nOK\n"
  line := " AT+CGMI?\r\n\n+CGMI=ASR\nOK\n"
  check2 := re2.has_matching line
  print check
  print check2