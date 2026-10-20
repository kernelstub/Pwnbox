{
  lib,
  stdenvNoCC,
  fetchzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sharphound";
  version = "2.17.0";

  src = fetchzip {
    url = "https://github.com/BloodHoundAD/SharpHound/releases/download/v${version}/SharpHound_v${version}_windows_x86.zip";
    sha256 = "sha256-DPfxMhyFgOUFMet7tZM2BaPsijaBt7gdlN3zTCwxTf4=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/sharphound" "$out/bin"
    cp -r SharpHound.exe SharpHound.exe.config SharpHound.ps1 "$out/share/sharphound/"

    cat > "$out/bin/sharphound" <<EOF
    #!${stdenvNoCC.shell}
    echo "SharpHound is a Windows .NET Framework collector and does not run on Linux."
    echo "Copy it to a domain-joined Windows host and run it there:"
    echo "  $out/share/sharphound/SharpHound.exe -c All --zip"
    EOF
    chmod +x "$out/bin/sharphound"

    runHook postInstall
  '';

  meta = with lib; {
    description = "SharpHound is the official BloodHound CE collector (Windows)";
    homepage = "https://github.com/BloodHoundAD/SharpHound";
    license = licenses.gpl3Only;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.all;
  };
}
