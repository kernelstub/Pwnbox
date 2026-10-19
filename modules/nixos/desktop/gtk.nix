{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    glib
    gtk3
    gtk4
    xsettingsd
  ];
}
