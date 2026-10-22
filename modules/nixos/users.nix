{
  config,
  lib,
  pkgs,
  ...
}:
let
  u = config.pwnbox;
  virtGroups =
    lib.optionals config.pwnbox.virtualisation.docker [ "docker" ]
    ++ lib.optionals config.pwnbox.virtualisation.libvirtd [
      "libvirtd"
      "kvm"
    ]
    ++ lib.optionals config.pwnbox.virtualisation.wireshark [ "wireshark" ];
in
{
  users.mutableUsers = true;

  users.users.${u.username} = {
    isNormalUser = true;
    description = u.fullName;
    shell = pkgs.zsh;
    extraGroups = lib.unique (
      [
        "networkmanager"
        "wheel"
      ]
      # hyprcorrect reads /dev/input/event* to buffer keystrokes for
      # system-wide typo correction.
      ++ lib.optionals config.pwnbox.desktop.enable [ "input" ]
      ++ virtGroups
      ++ u.extraGroups
    );
  };

  programs.zsh.enable = true;
}
