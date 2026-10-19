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

      # Architectures we build live/installer ISOs for. Add "riscv64-linux"
      # experimentally — expect toolset eval failures that need guarding.
      isoSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      envOr =
        name: fallback:
        let
          v = builtins.getEnv name;
        in
        if v == "" then fallback else v;
      detectedUser = envOr "PWNBOX_USER" (envOr "SUDO_USER" (envOr "USER" "pwnbox"));

      hostNames = builtins.attrNames (
        lib.filterAttrs (
          name: type:
          type == "directory"
          && builtins.pathExists (./hosts + "/${name}/default.nix")
          && !(builtins.elem name [
            "iso"
            "installer"
          ]) # image profiles, not hosts
        ) (builtins.readDir ./hosts)
      );

      # Shared module stack for hosts and images.
      commonModules = [
        ./modules/nixos
        ./modules/nixos/home-manager.nix
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ self.overlays.default ];
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.overwriteBackup = true;
        }
      ];

      mkHost =
        hostName:
        lib.nixosSystem {
          system = envOr "PWNBOX_SYSTEM" "x86_64-linux";
          specialArgs = { inherit inputs self; };
          modules = [
            ./hosts/${hostName}
          ]
          ++ commonModules
          ++ [
            {
              pwnbox.username = lib.mkDefault detectedUser;
              pwnbox.fullName = lib.mkDefault detectedUser;
            }
          ];
        };

      # ISO images always use an explicit system (never PWNBOX_SYSTEM).
      # withPwnbox: whether to include the pwnbox module stack (live images
      # yes; the installer ISO is a stock NixOS installer that merely carries
      # the flake source, and the pwnbox hardening clashes with the installer
      # profile, e.g. security.sudo-rs vs security.sudo).
      mkImage =
        name: system: modules: withPwnbox:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self; };
          modules =
            modules
            ++ [
              # Equivalent of the nixpkgs.hostPlatform line nixos-generate-config
              # writes into hardware-configuration.nix for regular hosts.
              # Several pwnbox modules read it, and the literal string avoids a
              # pkgs <-> hostPlatform evaluation cycle.
              { nixpkgs.hostPlatform = lib.mkDefault system; }
            ]
            ++ lib.optionals withPwnbox commonModules;
        };

      isoConfigs = builtins.listToAttrs (
        lib.concatMap (system: [
          {
            name = "iso-live-${system}";
            value = mkImage "live" system [ ./hosts/iso ] true;
          }
          {
            name = "iso-installer-${system}";
            value = mkImage "installer" system [ ./hosts/installer ] false;
          }
        ]) isoSystems
      );
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost // isoConfigs;

      # Convenience aliases: nix build .#images.<system>.{live,installer}
      images = lib.genAttrs isoSystems (system: {
        live = self.nixosConfigurations."iso-live-${system}".config.system.build.isoImage;
        installer = self.nixosConfigurations."iso-installer-${system}".config.system.build.isoImage;
      });

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
              # Packages like apktool drag x86_64-only deps (aapt) into their
              # closure; without this, non-x86_64 toolset envs refuse to
              # evaluate. Such packages may be runtime-broken off-x86.
              allowUnsupportedSystem = true;
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
