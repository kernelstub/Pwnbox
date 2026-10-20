{
  stdenvNoCC,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "pwnbox-dotfiles";
  version = "1.0.0";

  src = ../../dotfiles;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/pwnbox/dotfiles"
    cp -a . "$out/share/pwnbox/dotfiles/"
    runHook postInstall
  '';

  meta = {
    description = "pwnbox dotfiles (Hyprland, Quickshell, ranger, zsh, ...)";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.all;
  };
}
