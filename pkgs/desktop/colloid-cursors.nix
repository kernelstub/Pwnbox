{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "colloid-cursors";
  version = "2025-07-19";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Colloid-icon-theme";
    tag = finalAttrs.version;
    hash = "sha256-CzFEMY3oJE3sHdIMQQi9qizG8jKo72gR8FlVK0w0p74=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/icons"
    cp -r cursors/dist "$out/share/icons/Colloid-cursors"
    cp -r cursors/dist-dark "$out/share/icons/Colloid-dark-cursors"
    runHook postInstall
  '';

  meta = {
    description = "Colloid cursor themes for X11 and Wayland";
    homepage = "https://github.com/vinceliuice/Colloid-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
  };
})
