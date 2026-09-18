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
        pkgs.callPackage
          ({ lib
           , stdenvNoCC
           , makeWrapper
           , bun
           , clang ? null
           , libX11 ? null
           , xorgproto ? null
           , alsa-lib ? null
           , cudaPackages ? null
           , cudaToolkit ? (if cudaPackages == null then null else cudaPackages.cudatoolkit)
           , withX11 ? stdenvNoCC.hostPlatform.isLinux
           , withAlsa ? stdenvNoCC.hostPlatform.isLinux
           , withCuda ? false
           }:
            let
              x11Support = withX11 && libX11 != null && xorgproto != null;
              alsaSupport = withAlsa && alsa-lib != null;

              includePackages =
                lib.optionals x11Support [ libX11.dev xorgproto ]
                ++ lib.optionals alsaSupport [ alsa-lib.dev ]
                ++ lib.optional withCuda cudaToolkit;

              libraryPackages =
                lib.optional x11Support libX11
                ++ lib.optional alsaSupport alsa-lib
                ++ lib.optional withCuda cudaToolkit;

              includePath = lib.makeSearchPath "include" includePackages;
              libraryPath = lib.makeLibraryPath libraryPackages;

              wrapperArgs =
                [ ''--add-flags "$out/libexec/bend/bend2/main.ts"'' ]
                ++ lib.optional (clang != null) ''--prefix PATH : "${lib.makeBinPath [ clang ]}"''
                ++ lib.optional (clang == null && stdenvNoCC.hostPlatform.isDarwin) ''--set-default CC /usr/bin/clang''
                ++ lib.optional (includePath != "") ''--prefix CPATH : "${includePath}"''
                ++ lib.optional (libraryPath != "") ''--prefix LIBRARY_PATH : "${libraryPath}"''
                ++ lib.optional withCuda ''--set-default CUDA_HOME "${cudaToolkit}"'';
            in
            stdenvNoCC.mkDerivation
              (finalAttrs: {
                pname = "bend";
                version = "2.0.9";

                src = ./.;
                dontBuild = true;

                nativeBuildInputs = [ makeWrapper ];

                installPhase = ''
                  install -d "$out/libexec/bend" "$out/bin"
                  cp -r bend2 guide "$out/libexec/bend/"

                  makeWrapper "${bun}/bin/bun" \
                    "$out/bin/bend" \
                    ${lib.concatStringsSep " \\\n                  " wrapperArgs}
                '';

                doInstallCheck = true;
                installCheckPhase = ''
                  test "$($out/bin/bend --version)" = "bend ${finalAttrs.version}"
                  tmp=$(mktemp -d)
                  trap 'rm -rf "$tmp"' EXIT
                  "$out/bin/bend" guide > "$tmp/guide"
                  test -s "$tmp/guide"
                  "$out/bin/bend" base > "$tmp/base"
                  test -s "$tmp/base"
                  printf '%s\n' "import Base" "" "def main() -> U32:" "  42" > "$tmp/main.bend"
                  test "$($out/bin/bend "$tmp/main.bend")" = 42
                '';

                meta = {
                  description = "Massively parallel, high-level programming language";
                  homepage = "https://github.com/bendlang/bend";
                  license = lib.licenses.asl20;
                  platforms = lib.platforms.linux ++ lib.platforms.darwin;
                  mainProgram = "bend";
                };
              }))
          {
            clang = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.clang;
            libX11 = if pkgs.stdenv.hostPlatform.isLinux then pkgs.libX11 else null;
            xorgproto = if pkgs.stdenv.hostPlatform.isLinux then pkgs.xorgproto else null;
            alsa-lib = if pkgs.stdenv.hostPlatform.isLinux then pkgs.alsa-lib else null;
          };
    in
    {
      packages = forAllSystems (system: {
        default = package (import nixpkgs {
          inherit system;
        });
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
