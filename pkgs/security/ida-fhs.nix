{
  lib,
  buildFHSEnv,
  dbus,
  fontconfig,
  freetype,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libxkbcommon,
  wayland,
  xkeyboard_config,
  xorg,
  zlib,
  gsettings-desktop-schemas,
  hicolor-icon-theme,
  adwaita-icon-theme,
}:

buildFHSEnv {
  pname = "pwnbox-ida";
  version = "1.0.0";

  targetPkgs = pkgs: [
    pkgs.zlib
    pkgs.dbus.lib
    pkgs.libglvnd
    pkgs.libdrm
    pkgs.fontconfig.lib
    pkgs.freetype
    pkgs.glib
    pkgs.gtk3
    pkgs.wayland
    pkgs.libxkbcommon
    pkgs.xkeyboard_config
    pkgs.xorg.libX11
    pkgs.xorg.libXext
    pkgs.xorg.libXtst
    pkgs.xorg.libxcb
    pkgs.xorg.xcbutil
    pkgs.xorg.xcbutilwm
    pkgs.xorg.xcbutilimage
    pkgs.xorg.xcbutilkeysyms
    pkgs.xorg.xcbutilrenderutil
    pkgs.xorg.xcbutilcursor
    pkgs.gsettings-desktop-schemas
    pkgs.hicolor-icon-theme
    pkgs.adwaita-icon-theme
  ];

  multiPkgs = null;

  runScript = ''
    bash -c '
      set -e
      exe="''${PWNBOX_IDA_EXE:-ida}"
      case "$1" in
        ida|ida64|idat|hv|idapyswitch|lsadm) exe="$1"; shift ;;
      esac
      case "$exe" in
        ida|ida64|idat|hv|idapyswitch|lsadm) ;;
        *) echo "pwnbox-ida: unknown IDA executable: $exe" >&2; exit 1 ;;
      esac

      ida_dir="''${PWNBOX_IDA_HOME:-$HOME/Software/RE/IDA}"
      if [ "$exe" = "ida64" ] && [ ! -x "$ida_dir/ida64" ] && [ -x "$ida_dir/ida" ]; then
        exe=ida
      fi
      [ -x "$ida_dir/$exe" ] || {
        echo "pwnbox-ida: $exe not found in $ida_dir" >&2
        echo "Install IDA Free or Pro and set PWNBOX_IDA_HOME to its directory." >&2
        exit 1
      }

      cd "$ida_dir"
      exec "./$exe" "$@"
    ' bash "$@"
  '';

  extraInstallCommands = ''
        mkdir -p "$out/share/applications"
        for tool in ida ida64 idat hv; do
          cat > "$out/bin/$tool" <<EOF
    #!/bin/sh
    export PWNBOX_IDA_EXE="$tool"
    exec "$out/bin/pwnbox-ida" "\$@"
    EOF
          chmod +x "$out/bin/$tool"
        done

        cat > "$out/share/applications/idat.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=IDA (text mode)
    GenericName=Interactive Disassembler
    Comment=IDA Free / Pro text mode (pwnbox wrapper)
    Exec=$out/bin/idat %f
    Icon=ida
    Terminal=true
    Categories=Development;Debugger;ReverseEngineering;
    MimeType=application/x-executable;application/x-sharedlib;
    EOF
  '';

  meta = {
    description = "Run a locally installed IDA Free/Pro on NixOS (FHS environment with all required libraries)";
    mainProgram = "pwnbox-ida";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.unfree;
  };
}
