{ pkgs, categories }:
let
  inherit (pkgs) lib buildEnv;

  mkEnv =
    name: paths:
    buildEnv {
      inherit name paths;
      ignoreCollisions = true;
    };
in
{
  pwnbox = mkEnv "pwnbox-tools" (lib.flatten (lib.attrValues categories));
}
// lib.mapAttrs (name: paths: mkEnv "pwnbox-${name}" paths) categories
