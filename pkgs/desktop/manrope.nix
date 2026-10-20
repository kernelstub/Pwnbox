{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "manrope";
  version = "unstable-2026-03-13";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/5174b3333331c966c38f4355d50b03ca1c1df2f9/ofl/manrope/Manrope%5Bwght%5D.ttf";
    hash = "sha256-0GOb5F0K8255gXJBnXvRc8S9Tynit2y7adsdEb+LCkA=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" "$out/share/fonts/truetype/Manrope[wght].ttf"
    runHook postInstall
  '';

  meta = {
    description = "Manrope variable sans-serif font";
    homepage = "https://fonts.google.com/specimen/Manrope";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
