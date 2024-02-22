// Copyright (C) 2018 Toitware ApS. All rights reserved.
// Sketchy LoRa driver for RFM95.

import gpio
import monitor
import serial
import spi

class RFM95:
  static BAND_ ::= 868_000_000

  static REG_FIFO_ ::= 0x00
  static REG_OP_MODE_ ::= 0x01
  static REG_FRF_MSB_ ::= 0x06
  static REG_FRF_MID_ ::= 0x07
  static REG_FRF_LSB_ ::= 0x08
  static REG_PA_CONFIG_ ::= 0x09
  static REG_OCP_ ::= 0x0b
  static REG_LNA_ ::= 0x0c
  static REG_FIFO_ADDR_PTR_ ::= 0x0d
  static REG_FIFO_TX_BASE_ADDR_ ::= 0x0e
  static REG_FIFO_RX_BASE_ADDR_ ::= 0x0f
  static REG_FIFO_RX_CURRENT_ADDR_ ::= 0x10
  static REG_IRQ_FLAGS_ ::= 0x12
  static REG_RX_NB_BYTES_ ::= 0x13
  static REG_PKT_SNR_VALUE_ ::= 0x19
  static REG_PKT_RSSI_VALUE_ ::= 0x1a
  static REG_MODEM_CONFIG_1_ ::= 0x1d
  static REG_MODEM_CONFIG_2_ ::= 0x1e
  static REG_PREAMBLE_MSB_ ::= 0x20
  static REG_PREAMBLE_LSB_ ::= 0x21
  static REG_PAYLOAD_LENGTH_ ::= 0x22
  static REG_MODEM_CONFIG_3_ ::= 0x26
  static REG_FREQ_ERROR_MSB_ ::= 0x28
  static REG_FREQ_ERROR_MID_ ::= 0x29
  static REG_FREQ_ERROR_LSB_ ::= 0x2a
  static REG_RSSI_WIDEBAND_ ::= 0x2c
  static REG_DETECTION_OPTIMIZE_ ::= 0x31
  static REG_INVERTIQ_ ::= 0x33
  static REG_DETECTION_THRESHOLD_ ::= 0x37
  static REG_SYNC_WORD_ ::= 0x39
  static REG_INVERTIQ2_ ::= 0x3b
  static REG_DIO_MAPPING_1_ ::= 0x40
  static REG_VERSION_ ::= 0x42
  static REG_PA_DAC_ ::= 0x4d

  static MODE_LONG_RANGE_MODE_ ::= 0x80
  static MODE_SLEEP_ ::= 0x00
  static MODE_STDBY_ ::= 0x01
  static MODE_TX_ ::= 0x03
  static MODE_RX_CONTINUOUS_ ::= 0x05
  static MODE_RX_SINGLE_ ::= 0x06

  static PA_BOOST_ ::= 0x80

  static PA_OUTPUT_RFO_PIN_ ::= 0
  static PA_OUTPUT_PA_BOOST_PIN_ ::= 1

  static IRQ_TX_DONE_MASK_ ::= 0x08
  static IRQ_PAYLOAD_CRC_ERROR_MASK_ ::= 0x20
  static IRQ_RX_DONE_MASK_ ::= 0x40

  static MAX_PKT_LENGTH_ ::= 255

  mutex_ := monitor.Mutex
  registers_/spi.Registers
  dio0_/gpio.Pin?

  reading_ := false
  writing_ := false

  constructor device/serial.Device .dio0_:
    registers_ = device.registers as spi.Registers

    registers_.set_msb_write true

    if dio0_:
      dio0_.configure --input

    version := registers_.read_u8 REG_VERSION_
    if version != 0x12:
      throw "BAD_VERSION"

    sleep_

    set_frequency_ BAND_

    // set base addresses
    registers_.write_u8 REG_FIFO_TX_BASE_ADDR_ 0
    registers_.write_u8 REG_FIFO_RX_BASE_ADDR_ 0

    // set LNA boost
    registers_.write_u8 REG_LNA_ (registers_.read_u8 REG_LNA_) | 0x03

    // set auto AGC
    registers_.write_u8 REG_MODEM_CONFIG_3_ 0x04

    // set output power to 17 dBm
    set_tx_power_ 17 true

    disable_crc

    registers_.write_u8 REG_DIO_MAPPING_1_ 0x00

    explicit_header_mode_

    set_mode_

  set_mode_:
    mode := MODE_LONG_RANGE_MODE_
    if writing_: mode |= MODE_TX_
    else if reading_: mode |= MODE_RX_CONTINUOUS_
    else: mode |= MODE_STDBY_
    registers_.write_u8 REG_OP_MODE_ mode

  write data:
    // Check size.
    if data.size > MAX_PKT_LENGTH_: throw "OUT_OF_RANGE"
    if is_transmitting_: throw "SEND_IN_PROGRESS"

    mutex_.do:
      if writing_: throw "SEND_IN_PROGRESS"
      writing_ = true

      // Reset FIFO address.
      registers_.write_u8 REG_FIFO_ADDR_PTR_ 0

      // write data
      data.do: registers_.write_u8 REG_FIFO_ it

      // update length
      registers_.write_u8 REG_PAYLOAD_LENGTH_ data.size

      set_mode_

      // wait for TX done
      while (registers_.read_u8 REG_IRQ_FLAGS_) & IRQ_TX_DONE_MASK_ == 0:
        sleep --ms=1

      // clear IRQ's
      registers_.write_u8 REG_IRQ_FLAGS_ IRQ_TX_DONE_MASK_

      writing_ = false
      set_mode_

  read:
    if not dio0_: throw "DIO0 not configured"
    mutex_.do:
      if reading_: throw "READING_IN_PROGRESS"
      reading_ = true

    set_mode_

    dio0_.wait_for 1
    mutex_.do:
      irq_flags := registers_.read_u8 REG_IRQ_FLAGS_

      // clear IRQ's
      registers_.write_u8 REG_IRQ_FLAGS_ irq_flags

      if (irq_flags & IRQ_PAYLOAD_CRC_ERROR_MASK_) == 0:
        reading_ = false
        set_mode_

        // read packet length
        packet_length := registers_.read_u8 REG_RX_NB_BYTES_

        // set FIFO address to current RX address
        registers_.write_u8 REG_FIFO_ADDR_PTR_ (registers_.read_u8 REG_FIFO_RX_CURRENT_ADDR_)

        data := ByteArray packet_length:
          registers_.read_u8 REG_FIFO_

        return data
      return null  // TODO(florian,kasper): check missing return.
    unreachable

  is_transmitting_:
    if (registers_.read_u8 REG_OP_MODE_) & MODE_TX_ == MODE_TX_: return true

    if (registers_.read_u8 REG_IRQ_FLAGS_) & IRQ_TX_DONE_MASK_ != 0:
      // clear IRQ's
      registers_.write_u8 REG_IRQ_FLAGS_ IRQ_TX_DONE_MASK_

    return false

  set_coding_rate4 denominator:
    if denominator < 5:
      denominator = 5
    else if denominator > 8:
      denominator = 8

    cr := denominator - 4
    registers_.write_u8 REG_MODEM_CONFIG_1_ ((registers_.read_u8 REG_MODEM_CONFIG_1_) & 0xf1) | (cr << 1)

  set_preamble_length length:
    registers_.write_u8 REG_PREAMBLE_MSB_ length >> 8
    registers_.write_u8 REG_PREAMBLE_LSB_ length >> 0

  set_spreading_factor sf:
    if sf < 6:
      sf = 6
    else if sf > 12:
      sf = 12

    if sf == 6:
      registers_.write_u8 REG_DETECTION_OPTIMIZE_ 0xc5
      registers_.write_u8 REG_DETECTION_THRESHOLD_ 0x0c
    else:
      registers_.write_u8 REG_DETECTION_OPTIMIZE_ 0xc3
      registers_.write_u8 REG_DETECTION_THRESHOLD_ 0x0a

    registers_.write_u8 REG_MODEM_CONFIG_2_ ((registers_.read_u8 REG_MODEM_CONFIG_2_) & 0x0f) | ((sf << 4) & 0xf0)
    set_ldo_flag_

  set_signal_bandwidth sbw:
    bw := 0

    if sbw <= 7_800:
      bw = 0
    else if sbw <= 10_400:
      bw = 1
    else if sbw <= 15_600:
      bw = 2
    else if sbw <= 20_800:
      bw = 3
    else if sbw <= 31_250:
      bw = 4
    else if sbw <= 41_700:
      bw = 5
    else if sbw <= 62_500:
      bw = 6
    else if sbw <= 125_000:
      bw = 7
    else if sbw <= 250_000:
      bw = 8
    else:
      bw = 9

    registers_.write_u8 REG_MODEM_CONFIG_1_ ((registers_.read_u8 REG_MODEM_CONFIG_1_) & 0x0f) | (bw << 4)
    set_ldo_flag_

  get_signal_bandwidth:
    bw := (registers_.read_u8 REG_MODEM_CONFIG_1_) >> 4

    if bw == 0: return 7_800
    if bw == 1: return 10_400
    if bw == 2: return 15_600
    if bw == 3: return 20_800
    if bw == 4: return 31_250
    if bw == 5: return 41_700
    if bw == 6: return 62_500
    if bw == 7: return 125_000
    if bw == 8: return 250_000
    if bw == 9: return 500_000
    return -1

  enable_crc:
    registers_.write_u8 REG_MODEM_CONFIG_2_ (registers_.read_u8 REG_MODEM_CONFIG_2_) | 0x04

  disable_crc:
    registers_.write_u8 REG_MODEM_CONFIG_2_ (registers_.read_u8 REG_MODEM_CONFIG_2_) & 0xfb

  get_spreading_factor:
    return (registers_.read_u8 REG_MODEM_CONFIG_2_) >> 4

  explicit_header_mode_:
    registers_.write_u8 REG_MODEM_CONFIG_1_ (registers_.read_u8 REG_MODEM_CONFIG_1_) & 0xfe

  implicit_header_mode_:
    registers_.write_u8 REG_MODEM_CONFIG_1_ (registers_.read_u8 REG_MODEM_CONFIG_1_) | 0x01

  set_tx_power_ level boost:
    if not boost:
      // RFO
      if level < 0:
        level = 0
      else if level > 14:
        level = 14;

      registers_.write_u8 REG_PA_CONFIG_ 0x70 | level
    else:
      // PA BOOST
      if level > 17:
        if level > 20: level = 20

        // subtract 3 from level, so 18 - 20 maps to 15 - 17
        level -= 3

        // High Power +20 dBm Operation (Semtech SX1276/77/78/79 5.4.3.)
        registers_.write_u8 REG_PA_DAC_ 0x87
        set_OCP_ 140
      else:
        if level < 2: level = 2

        // Default value PA_HF/LF or +17dBm
        registers_.write_u8 REG_PA_DAC_ 0x84
        set_OCP_ 100

      registers_.write_u8 REG_PA_CONFIG_ PA_BOOST_ | (level - 2)


  set_frequency_ hz:
    frf := (hz << 19) / 32000000

    registers_.write_u8 REG_FRF_MSB_ frf >> 16
    registers_.write_u8 REG_FRF_MID_ frf >> 8
    registers_.write_u8 REG_FRF_LSB_ frf >> 0

  set_OCP_ mA:
    ocp_trim := 27

    if mA <= 120:
      ocp_trim = (mA - 45) / 5
    else if mA <= 240:
      ocp_trim = (mA + 30) / 10

    registers_.write_u8 REG_OCP_ 0x20 | (0x1F & ocp_trim)

  set_ldo_flag_:
    // Section 4.1.1.5
    symbol_duration := 1000 / (get_signal_bandwidth / (1 << get_spreading_factor))

    // Section 4.1.1.6
    ldo_on := symbol_duration > 16 ? 1 : 0

    config3 := registers_.read_u8 REG_MODEM_CONFIG_3_

    // Expansion of "bitWrite(config3, 3, ldoOn)"
    config3 = (config3 & ~(1 << 3)) | (ldo_on << 3)

    registers_.write_u8 REG_MODEM_CONFIG_3_ config3

  sleep_:
    registers_.write_u8 REG_OP_MODE_ MODE_LONG_RANGE_MODE_ | MODE_SLEEP_