{
  description = "Bend 2: a fast, dependently typed, massively parallel language";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      package = pkgs:
        pkgs.callPackage ./nix/package.nix {
          clang = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.clang;
          libX11 = if pkgs.stdenv.hostPlatform.isLinux then pkgs.libX11 else null;
          xorgproto = if pkgs.stdenv.hostPlatform.isLinux then pkgs.xorgproto else null;
          alsa-lib = if pkgs.stdenv.hostPlatform.isLinux then pkgs.alsa-lib else null;
        };
    in
    {
      packages = forAllSystems (system: {
        default = package (import nixpkgs { inherit system; });
      });

      apps = forAllSystems (system:
        let
          bend = package (import nixpkgs { inherit system; });
        in
        {
          default = {
            type = "app";
            program = "${bend}/bin/bend";
            meta = {
              description = "Bend 2 compiler and interpreter";
            };
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.bun ] ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.clang;
          };
        });
    };
}
