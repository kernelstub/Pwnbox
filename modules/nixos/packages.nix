{
  config,
  lib,
  pkgs,
  inputs ? null,
  ...
}:
let
  inherit (lib) optionals;

  categories = import ../../pkgs/categories.nix {
    inherit pkgs;
    inputs = if inputs == null then { } else inputs;
    system = pkgs.stdenv.hostPlatform.system;
  };
  enabledToolCategories = lib.filter (n: config.pwnbox.packages.toolset.${n}.enable) (
    builtins.attrNames categories
  );

  availableOnThis = lib.meta.availableOn pkgs.stdenv.hostPlatform;

  pentestTools = pkgs.buildEnv {
    name = "pwnbox-tools";
    paths = lib.flatten (map (n: lib.filter availableOnThis categories.${n}) enabledToolCategories);
    ignoreCollisions = true;
  };

  zenBrowser =
    if inputs != null && inputs ? zen-browser then
      pkgs.callPackage ../../pkgs/apps/browsers/zen-browser.nix {
        zen-browser-unwrapped =
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped;
        pywalfox = pkgs.callPackage ../../pkgs/apps/browsers/pywalfox-native.nix { };
      }
    else
      null;

  chatgpt =
    if inputs != null && inputs ? chatgpt then
      (inputs.chatgpt.packages.${pkgs.stdenv.hostPlatform.system} or { }).chatgpt or null
    else
      null;

  custom = import ../../pkgs/custom.nix { inherit pkgs; };

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      requests
      colorama
      pyautogui
      pyperclip
      pillow
      pygments
    ]
  );

  base = with pkgs; [
    figlet

    git
    git-lfs
    gh
    lazygit
    wget
    curl
    unzip
    zip
    p7zip
    unrar
    rsync
    rclone
    jq
    bc
    tree
    file
    which
    psmisc
    plocate
    trash-cli
    man
    man-pages
    less

    zsh
    fzf
    ripgrep
    fd
    eza
    bat
    zoxide
    direnv

    micro
    vim
    neovim
    tmux
    screen

    htop
    btop
    lshw
    pciutils
    usbutils
    lm_sensors

    fastfetch

    gcc
    gnumake
    pkg-config
    nodejs
    bun
    pnpm
    go

    nixfmt
    statix
    deadnix

    pythonEnv
  ];

  desktop = with pkgs; [
    hyprlock
    hypridle
    hyprshot
    hyprpicker
    hyprpolkitagent
    quickshell
    wlr-randr
    fuzzel
    rofi
    pywal16
    pywalfox-native
    swaybg
    awww
    wl-clipboard
    cliphist
    wtype
    brightnessctl
    playerctl
    pamixer
    pavucontrol
    easyeffects
    gnome-keyring
    libsecret

    grim
    slurp
    swappy
    wf-recorder

    imv
    mpv
    ffmpeg
    imagemagick

    kitty
    ranger
    zathura
    hyfetch

    mpc
    cmus
    cava

    nwg-look
    adwaita-icon-theme
    papirus-icon-theme
    pwnbox.colloid-cursors
    (colloid-icon-theme.override { colorVariants = [ "grey" ]; })
    gnome-themes-extra
    gsettings-desktop-schemas

    xdg-utils
    xdg-user-dirs
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    gvfs
    udisks2
    udiskie
    ntfs3g
    exfat
    exfatprogs

    xwayland
    xrandr
    xrdb
    xsetroot
    xdotool
    wmctrl
    xclip

    yt-dlp
    spotdl

    (writeShellScriptBin "ytdl" ''exec ${yt-dlp}/bin/yt-dlp "$@"'')
  ];

  apps =
    with pkgs;
    [
      chromium

      signal-desktop
      session-desktop
      ayugram-desktop
      element-desktop
      wire-desktop
      simplex-chat-desktop
      dino
      qtox
      equibop
      goofcord

      obsidian
      zed-editor
      geary
      keepassxc

      qbittorrent
      vlc

      pwncat

      mullvad-vpn

      tor
      torsocks
    ]
    ++ optionals pkgs.stdenv.isx86_64 [
      exodus
      ledger-live-desktop
      (pkgs.callPackage ../../pkgs/apps/browsers/tor-browser.nix { })
      mullvad-browser
      spotify
      spicetify-cli
    ];

  gaming = with pkgs; [
    lutris
    gamemode
    mangohud
    wineWow64Packages.stable
    protonup-ng
  ];

  creative = with pkgs; [
    gimp
    inkscape
    libreoffice-fresh
    kdePackages.kdenlive
    obs-studio
    audacity
    blender
    krita
  ];

  languages = with pkgs; [
    clang
    clang-tools

    rustc
    cargo
    rust-analyzer

    zig
    zls

    dotnet-sdk

    jdk21
    kotlin
    scala

    uv
    pipx

    ruby
    php
    perl
    lua5_4
    luajit

    deno
    typescript

    elixir
    erlang

    ghc
    cabal-install
    stack

    ocaml
    nim
    R
    julia
    clojure
    groovy
    crystal

    powershell
    dart
  ];

in
{
  environment.systemPackages =
    base
    ++ optionals config.pwnbox.desktop.enable desktop
    ++ apps
    ++ optionals (chatgpt != null) [ chatgpt ]
    ++ optionals config.pwnbox.packages.gaming gaming
    ++ optionals config.pwnbox.packages.creative creative
    ++ optionals (zenBrowser != null) [ zenBrowser ]
    ++ optionals config.pwnbox.packages.hacking (
      [
        pentestTools
      ]
      ++ optionals pkgs.stdenv.isx86_64 [
        pkgs.pwnbox.ida
      ]
    )
    ++ languages
    ++ custom;

  nixpkgs.config = lib.mkIf config.pwnbox.packages.hacking {
    allowInsecurePredicate = _: true;
    android_sdk.accept_license = true;
  };

  environment.sessionVariables =
    lib.mkIf (config.pwnbox.packages.hacking && config.pwnbox.packages.toolset.wordlists.enable)
      {
        SECLISTS_DIR = "${pkgs.seclists}/share/wordlists/seclists";
        WORDLISTS_DIR = "${pkgs.wordlists}/share/wordlists";
      };

  programs.appimage.enable = true;

  hardware.ledger.enable = true;

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "kitty.desktop" ];
  };

  xdg.mime.defaultApplications = {
    "text/html" = "zen.desktop";
    "text/xml" = "zen.desktop";
    "application/xhtml+xml" = "zen.desktop";
    "application/vnd.mozilla.xul+xml" = "zen.desktop";
    "x-scheme-handler/http" = "zen.desktop";
    "x-scheme-handler/https" = "zen.desktop";
    "x-scheme-handler/about" = "zen.desktop";
    "x-scheme-handler/unknown" = "zen.desktop";

    "text/plain" = "dev.zed.Zed.desktop";
    "text/markdown" = "dev.zed.Zed.desktop";
    "text/x-python" = "dev.zed.Zed.desktop";
    "application/x-shellscript" = "dev.zed.Zed.desktop";
    "application/json" = "dev.zed.Zed.desktop";
    "application/toml" = "dev.zed.Zed.desktop";
    "application/yaml" = "dev.zed.Zed.desktop";
    "text/css" = "dev.zed.Zed.desktop";
    "text/javascript" = "dev.zed.Zed.desktop";
    "text/rust" = "dev.zed.Zed.desktop";
    "text/x-go" = "dev.zed.Zed.desktop";
    "text/x-lua" = "dev.zed.Zed.desktop";
    "text/x-csrc" = "dev.zed.Zed.desktop";
    "text/x-chdr" = "dev.zed.Zed.desktop";
    "text/x-c++src" = "dev.zed.Zed.desktop";
    "text/x-c++hdr" = "dev.zed.Zed.desktop";
    "text/x-java" = "dev.zed.Zed.desktop";
    "application/x-ruby" = "dev.zed.Zed.desktop";
    "application/sql" = "dev.zed.Zed.desktop";

    "image/png" = "org.gnome.Loupe.desktop";
    "image/jpeg" = "org.gnome.Loupe.desktop";
    "image/gif" = "org.gnome.Loupe.desktop";
    "image/webp" = "org.gnome.Loupe.desktop";
    "image/avif" = "org.gnome.Loupe.desktop";
    "image/bmp" = "org.gnome.Loupe.desktop";
    "image/tiff" = "org.gnome.Loupe.desktop";
    "image/svg+xml" = "org.gnome.Loupe.desktop";
    "image/jxl" = "org.gnome.Loupe.desktop";
    "image/heic" = "org.gnome.Loupe.desktop";
    "application/pdf" = "org.gnome.Papers.desktop";
    "application/x-bzpdf" = "org.gnome.Papers.desktop";
    "application/x-gzpdf" = "org.gnome.Papers.desktop";
    "application/x-xzpdf" = "org.gnome.Papers.desktop";
  };

  programs.steam = lib.mkIf config.pwnbox.packages.gaming {
    enable = true;
    remotePlay.openFirewall = true;
  };
}
