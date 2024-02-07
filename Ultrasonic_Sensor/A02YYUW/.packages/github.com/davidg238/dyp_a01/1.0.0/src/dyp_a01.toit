// Copyright 2021 Ekorau LLC

import serial
import gpio
import serial.ports.uart show Port

/**
A library to measure distance using the DYP-A01-V2.0
  ultrasonic sensor, available from https://www.adafruit.com/product/4664
*/
class DYP_A01:
  hi := 0
  lo := 0

  tx/gpio.Pin
  rx/gpio.Pin
  port/Port

  constructor --tx_pin/int --rx_pin/int:
    tx = gpio.Pin tx_pin // Not connected.
    rx = gpio.Pin rx_pin
    port = Port
            --tx=tx      // Not used this version.
            --rx=rx
            --baud_rate=9600

  off:
    port.close 

  range -> int:                 // Range to target, in mm.
    val := range_
    if val < 0: val = range_    // Retry 3 times, to resync frames.
    if val < 0: val = range_
    if val < 0: val = range_
    return val

  range_ -> int:
    // A return value of 0 from the sensor indicates the target is too close,
    //   within the sensor dead zone.
    frame := port.read
    if frame.size != 4:  return -1 // Wrong frame size.
    if frame[0] != 0xFF: return -2 // wrong start byte.
    hi = frame[1]
    lo = frame[2]
    sum := frame[3]
    chksum := (0xFF + hi + lo) & 0x00FF
    if sum != chksum:    return -3 // Wrong checksum.
    val := (hi << 8) + lo
    return val
