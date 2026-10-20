{
  lib,
  python3,
  stdenvNoCC,
}:
let
  py = python3;
  impacket = py.pkgs.impacket;

  notACli = [
    "__init__"
    "config"
    "identity_log"
    "logger"
    "os_ident"
    "rpcdatabase"
    "serviceinstall"
    "targetsutils"
    "utils"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "impacket-tools";
  version = impacket.version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    for s in ${impacket}/bin/*.py; do
      ln -s "$s" "$out/bin/$(basename "$s" .py)"
    done

    for s in ${impacket}/lib/${py.libPrefix}/site-packages/impacket/examples/*.py; do
      name="$(basename "$s" .py)"
      case " ${lib.concatStringsSep " " notACli} " in
        *" $name "*) continue ;;
      esac
      [ -e "$out/bin/$name" ] || ln -s "$s" "$out/bin/$name"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Every impacket example script as a standalone command (mssqlclient, secretsdump, psexec, ntlmrelayx, ...)";
    homepage = "https://github.com/fortra/impacket";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
