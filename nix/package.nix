{ lib
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
, sourcePath ? ../.
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

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bend";
  version = "2.0.7";

  src = sourcePath;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -d "$out/libexec/bend" "$out/bin"
    cp -r bend2 guide "$out/libexec/bend/"

    makeWrapper "${bun}/bin/bun" \
      "$out/bin/bend" \
      ${lib.concatStringsSep " \\\n      " wrapperArgs}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    test "$($out/bin/bend --version)" = "bend ${finalAttrs.version}"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
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
})
