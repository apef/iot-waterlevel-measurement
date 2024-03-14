# Toit package: case

Utilities for upper and lower case of Unicode strings.

This code uses a very compact encoding of the upper- and lower-case
information from Unicode.  It is intended to be compact enough for
embedded devices.

This code was originally written in Dart for the Dartino project and has
been ported to Toit by Toitware.

## Examples

```
import case

main:
  print
      case.to_upper "foo"   // Prints "FOO"
  print
      case.to_upper "Straßenbahn"   // Prints "STRASSENBAHN"
  print
      case.to_lower "Доверяй, но проверяй"   // Prints "доверяй, но проверяй."
```
