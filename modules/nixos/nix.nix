{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = 4;
    cores = 2;
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
    keep-outputs = false;
    keep-derivations = false;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    zstd
    xz
    bzip2
    openssl
    fuse
    fuse3
    libglvnd
    libdrm
    libx11
    libxext
    libxtst
    libxrender
    libxfixes
    libxi
    libxrandr
    libxcursor
    libxcomposite
    libxdamage
    libxinerama
    libxscrnsaver
    libsm
    libice
    libxcb
    libxcb-util
    libxcb-wm
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-cursor
    wayland
    libxkbcommon
    glib
    gtk3
    fontconfig.lib
    freetype
    dbus.lib
  ];
}
