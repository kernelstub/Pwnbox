{
  config,
  pkgs,
  ...
}:
{
  services.mullvad-vpn = {
    enable = config.pwnbox.vpn.mullvad;
    package = pkgs.mullvad-vpn;
  };
}
