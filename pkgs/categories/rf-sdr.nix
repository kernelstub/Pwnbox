{ pkgs, ... }:
let
  pkgs' = pkgs.extend (
    final: prev: {
      soapyuhd = prev.stdenvNoCC.mkDerivation {
        pname = "soapyuhd";
        version = "stub";
        dontUnpack = true;
        dontBuild = true;
        installPhase = "mkdir -p $out";
      };
    }
  );
in
with pkgs';
[
  hackrf
  rtl-sdr
  rtl_433
  sdrpp
  urh
  gqrx
  inspectrum
  multimon-ng
]
