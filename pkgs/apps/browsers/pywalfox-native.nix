{
  lib,
  pywalfox-native,
  runCommand,
  writeText,
}:
let
  manifest = writeText "pywalfox.json" (
    builtins.toJSON {
      name = "pywalfox";
      description = "Native app used alongside the Pywalfox addon";
      path = "${lib.getExe pywalfox-native}";
      type = "stdio";
      allowed_extensions = [ "pywalfox@frewacom.org" ];
    }
  );
in
runCommand "pywalfox-native-host" { } ''
  mkdir -p "$out/lib/mozilla/native-messaging-hosts"
  cp ${manifest} "$out/lib/mozilla/native-messaging-hosts/pywalfox.json"
''
