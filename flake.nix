{
  description = "Bend - a fast language that blocks AI mistakes via proof";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          default = bend;
          bend = pkgs.callPackage ./nix/package.nix { src = self; };
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux rec {
          default-cuda = bend-cuda;

          bend-cuda = pkgs.callPackage ./nix/package.nix {
            src = self;
            cudaSupport = true;
          };
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.bend;
          meta.description = "Run the Bend compiler";
        };
      });

      checks = forAllSystems (system: {
        package = self.packages.${system}.bend;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.bun
              pkgs.clang_19
            ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.alsa-lib
              pkgs.libX11
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      lib = {
        mkBend = import ./nix/lib.nix {
          inherit self;
          inherit (nixpkgs) lib;
        };
      };

      nixosModules = rec {
        default = bend;
        bend = import ./nix/modules/nixos.nix { inherit self; };
      };

      homeModules = rec {
        default = bend;
        bend = import ./nix/modules/home-manager.nix { inherit self; };
      };

      homeManagerModules = self.homeModules;
    };
}
