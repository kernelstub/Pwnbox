{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    excludePackages = [ pkgs.xterm ];
  };

  services.libinput.enable = true;

  hardware.graphics = {
    enable = true;
    # 32-bit graphics libs only exist on x86_64
    enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
