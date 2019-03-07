{ system ? builtins.currentSystem # TODO: Get rid of this system cruft
, iosSdkVersion ? "10.2"
, withHoogle ? false # to spin up localhost:8080 hoogle use: nix-shell --arg withHoogle true -A shells.ghc --command "hoogle server -p 8080 --local"
}:
let
  obelisk = import .obelisk/impl { inherit system iosSdkVersion; };
in obelisk.project ./. ({ pkgs, ... }:
  let

  in {
    inherit withHoogle;
    staticFiles = pkgs.callPackage ./static { pkgs = obelisk.nixpkgs; };
    android.applicationId = "systems.obsidian.obelisk.examples.minimal";
    android.displayName = "Obelisk Minimal Example";
    ios.bundleIdentifier = "systems.obsidian.obelisk.examples.minimal";
    ios.bundleName = "Obelisk Minimal Example";
  })
