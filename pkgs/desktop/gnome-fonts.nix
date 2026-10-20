{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "pwnbox-gnome-fonts";
  version = "1.0.0";

  src = ../../dotfiles/gnome/fonts;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/fonts/gnome"
    cp -a . "$out/share/fonts/gnome/"
    runHook postInstall
  '';

  meta = {
    description = "Fonts from the pwnbox GNOME dotfiles (Manrope, Fairfax Hax HD, ...)";
    license = lib.licenses.unfreeRedistributable;
    platforms = lib.platforms.all;
  };
}
