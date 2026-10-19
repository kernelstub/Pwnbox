{
  pkgs,
  inputs ? { },
  system ? pkgs.stdenv.hostPlatform.system,
  lib ? pkgs.lib,
}:
let
  call =
    file:
    import file {
      inherit
        pkgs
        lib
        system
        inputs
        ;
    };
in
{
  reconnaissance = call ./categories/reconnaissance.nix;
  web = call ./categories/web.nix;
  exploitation = call ./categories/exploitation.nix;
  active-directory = call ./categories/active-directory.nix;
  network = call ./categories/network.nix;
  wireless = call ./categories/wireless.nix;
  bluetooth = call ./categories/bluetooth.nix;
  rf-sdr = call ./categories/rf-sdr.nix;
  hardware = call ./categories/hardware.nix;
  firmware = call ./categories/firmware.nix;
  reverse-engineering = call ./categories/reverse-engineering.nix;
  binary-exploitation = call ./categories/binary-exploitation.nix;
  fuzzing = call ./categories/fuzzing.nix;
  forensics = call ./categories/forensics.nix;
  blue-team = call ./categories/blue-team.nix;
  cloud = call ./categories/cloud.nix;
  containers = call ./categories/containers.nix;
  kubernetes = call ./categories/kubernetes.nix;
  code-analysis = call ./categories/code-analysis.nix;
  password-cracking = call ./categories/password-cracking.nix;
  cryptography = call ./categories/cryptography.nix;
  wordlists = call ./categories/wordlists.nix;
  mobile = call ./categories/mobile.nix;
  voip = call ./categories/voip.nix;
  smartcards = call ./categories/smartcards.nix;
  python = call ./categories/python.nix;
}
