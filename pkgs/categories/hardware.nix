{ pkgs, ... }:
with pkgs;
[
  esptool
  openocd
  flashrom
  avrdude
  stlink
  picocom

  sigrok-cli
  pulseview

  dmidecode
  i2c-tools

  gtkwave
  iverilog
  verilator
  yosys

  minicom
  dfu-util
  sdcc
  openfpgaloader
  urjtag
]
