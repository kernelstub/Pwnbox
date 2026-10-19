{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-shell-extensions
    gnomeExtensions.user-themes
    gnomeExtensions.lockscreen-extension
    gnomeExtensions.hide-top-bar
    gnomeExtensions.notification-configurator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.tiling-shell
    gnomeExtensions.rounded-window-corners-reborn

    colloid-gtk-theme
  ];

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
    yelp
    gnome-maps
    gnome-weather
    gnome-music
    gnome-contacts
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-logs
    gnome-software
    epiphany
    totem
    simple-scan
    cheese
    gnome-boxes
    gnome-connections
  ];
}
