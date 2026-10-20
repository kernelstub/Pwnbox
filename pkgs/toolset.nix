{ pkgs, categories }:
let
  inherit (pkgs) lib buildEnv;

  available = lib.meta.availableOn pkgs.stdenv.hostPlatform;
  categories' = lib.mapAttrs (_: lib.filter available) categories;

  mkEnv =
    name: paths:
    buildEnv {
      inherit name paths;
      ignoreCollisions = true;
    };
in
{
  pwnbox = mkEnv "pwnbox-tools" (lib.flatten (lib.attrValues categories'));
}
// lib.mapAttrs (name: paths: mkEnv "pwnbox-${name}" paths) categories'
