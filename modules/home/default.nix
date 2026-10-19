{ ... }:
{
  imports = [
    ./dotfiles.nix
    ./shell.nix
    ./packages.nix
    ./gtk.nix
    ./neovim.nix
  ];
}
