{
  description = "pwnbox: portable hardened NixOS + home-manager configuration (Hyprland + GNOME + Quickshell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chatgpt = {
      url = "github:csoftware-arigpt/nixos-chatgpt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;

      envOr =
        name: fallback:
        let
          v = builtins.getEnv name;
        in
        if v == "" then fallback else v;
      detectedUser = envOr "PWNBOX_USER" (envOr "SUDO_USER" (envOr "USER" "pwnbox"));

      hostNames = builtins.attrNames (
        lib.filterAttrs (
          name: type: type == "directory" && builtins.pathExists (./hosts + "/${name}/default.nix")
        ) (builtins.readDir ./hosts)
      );

      mkHost =
        hostName:
        lib.nixosSystem {
          system = envOr "PWNBOX_SYSTEM" "x86_64-linux";
          specialArgs = { inherit inputs self; };
          modules = [
            ./hosts/${hostName}
            ./modules/nixos
            ./modules/nixos/home-manager.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs.overlays = [ self.overlays.default ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.overwriteBackup = true;

              pwnbox.username = lib.mkDefault detectedUser;
              pwnbox.fullName = lib.mkDefault detectedUser;
            }
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      nixosModules.default = import ./modules/nixos;
      nixosModules.home-manager = import ./modules/nixos/home-manager.nix;

      homeManagerModules.default = import ./modules/home;

      overlays.default = import ./overlays;

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              allowInsecurePredicate = _: true;
              android_sdk.accept_license = true;
            };
            overlays = [ self.overlays.default ];
          };
          categories = import ./pkgs/categories.nix { inherit pkgs inputs system; };
        in
        (import ./pkgs { inherit pkgs; })
        // (import ./pkgs/toolset.nix { inherit pkgs categories; })
        // lib.optionalAttrs (system == "x86_64-linux") {
          chatgpt = inputs.chatgpt.packages.${system}.chatgpt;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            nixfmt
            statix
            deadnix
          ];
        };
      });
    };
}
