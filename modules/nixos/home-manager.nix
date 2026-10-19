{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.pwnbox.username;
in
{
  home-manager.extraSpecialArgs = {
    pwnboxDisplay = config.pwnbox.desktop.resolution;
    pwnboxMainMonitor = config.pwnbox.desktop.mainMonitor;
    pwnboxLeftMonitor = config.pwnbox.desktop.leftMonitor;
    pwnboxTimezone = config.pwnbox.timeZone;
  };

  home-manager.users.${user} = {
    imports = [ ../home ];

    home.username = user;
    home.homeDirectory = lib.mkDefault "/home/${user}";
    home.stateVersion = "26.05";
  };
}
