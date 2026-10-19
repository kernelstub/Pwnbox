{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation {
  pname = "spicetify-marketplace";
  version = "1.0.11";

  src = fetchurl {
    url = "https://github.com/spicetify/marketplace/releases/download/v1.0.11/marketplace.zip";
    sha256 = "sha256-6pDqKSYhydFkOnHF65OeifBo81WODSt4nrRvkKkzEi8=";
  };

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/spicetify-marketplace"
    cd "$out/share/spicetify-marketplace"
    unzip -q "$src"
    mv marketplace-dist marketplace
    runHook postInstall
  '';

  meta = {
    description = "Spicetify Marketplace: extensions, themes and snippets browser for Spotify";
    homepage = "https://github.com/spicetify/marketplace";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
  };
}
