{ pkgs, ... }:
with pkgs;
[
  android-tools
  scrcpy
  apktool
  jadx
  frida-tools
  dex2jar
  apksigner

  objection
  libimobiledevice
  usbmuxd
  idevicerestore
]
