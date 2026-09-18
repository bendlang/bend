{
  self,
  optionPath ? [ "bend" ],
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = lib.attrByPath optionPath { } config;

  bendPackage = pkgs.callPackage ./package.nix {
    src = lib.cleanSource self.outPath;
    cudaSupport = cfg.cuda.enable;
    cudaPackages = cfg.cuda.packages;
  };
in
{
  options = lib.setAttrByPath optionPath {
    cuda = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = pkgs.config.cudaSupport;
        defaultText = lib.literalExpression "pkgs.config.cudaSupport";
        description = "Whether to support CUDA in generated Bend executables.";
      };

      packages = lib.mkOption {
        # A Nixpkgs CUDA package set contains aliases and package functions, so
        # it is intentionally opaque here; package.nix selects only what it uses.
        type = lib.types.raw;
        default = pkgs.cudaPackages_12;
        defaultText = lib.literalExpression "pkgs.cudaPackages_12";
        description = "CUDA package set used when CUDA support is enabled.";
      };
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = bendPackage;
      defaultText = lib.literalExpression "the Bend package configured by these options";
      description = "The Bend package to install.";
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.setAttrByPath optionPath { finalPackage = cfg.package; };
}
