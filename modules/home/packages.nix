{ pkgs, ... }:
{
  home.packages = with pkgs; [
    keepassxc
    flameshot
    pavucontrol

    pkgs.pwnbox.tg-config

    (writeShellScriptBin "zed" ''exec ${zed-editor}/bin/zeditor "$@"'')
  ];
}
