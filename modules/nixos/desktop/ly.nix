{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  services.displayManager.ly = {
    enable = true;
    settings = {
      hide_borders = true;
    };
  };

  services.displayManager.defaultSession = "hyprland";
}
