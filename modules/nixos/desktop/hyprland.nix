{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = false;
    systemd.setPath.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    BROWSER = "zen";
    DEFAULT_BROWSER = "zen";
    XCURSOR_THEME = "Colloid-dark-cursors";
    XCURSOR_SIZE = "24";
  };

  environment.systemPackages = with pkgs; [
    hyprlock
    hypridle
    hyprshot
    hyprpicker
    hyprpolkitagent
  ];
}
