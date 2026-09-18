{ self, lib }:
{
  pkgs,
  modules ? [ ],
  extraSpecialArgs ? { },
}:
let
  evaluated = lib.evalModules {
    specialArgs = {
      inherit self pkgs;
    }
    // extraSpecialArgs;
    modules = [ (import ./options.nix { inherit self; }) ] ++ modules;
  };
  cfg = evaluated.config.bend;
in
{
  inherit (evaluated) config options;
  cudaSupport = cfg.cuda.enable;
  cudaPackages = cfg.cuda.packages;
  package = cfg.finalPackage;
}
