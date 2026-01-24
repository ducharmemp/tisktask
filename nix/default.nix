{ pkgs ? import <nixpkgs> { }, port ? 4000, ... }:
let
  beamPackages = pkgs.beamPackages;
  fs = pkgs.lib.fileset;
  inherit (beamPackages) mixRelease;
  heroicons = pkgs.stdenv.mkDerivation {
    name = "heroicons";
    version = "2.2.0";
    src = builtins.fetchGit {
      url = "git@github.com:tailwindlabs/heroicons";
      rev = "0435d4ca364a608cc75e2f8683d374e55abbae26";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ./* $out
      runHook postInstall
    '';
  };
in 
mixRelease rec {
  pname = "tisktask";
  version = "0.0.1";
  removeCookie = false;
  nativeBuildInputs = with pkgs; [ esbuild tailwindcss_3 ];
  erlangDeterministicBuilds = false;

  PORT = "${toString (port)}";
  RELEASE_COOKIE = "SUPER_SECRET_SECRET_COOKIE";
  SECRET_KEY_BASE = "SUPER_SECRET_SECRET_KEYBASE";

  # Uncomment to use a git repo to pull in the source
  # src = builtins.fetchGit {
  #   url = "git@host/repo.git";
  #   rev = commit;
  #   ref = branch;
  # };

  # This will use the current directory as source
  src = fs.toSource {
    root = ../.;
    fileset = fs.unions [
      ./_build/tailwind-linux-x64
    (fs.difference ./. ( fs.unions [ (fs.maybeMissing ./result) ./deps ./_build ]))
    ];
  };

  mixNixDeps = import "${src}/mix.nix" {
    inherit (pkgs) lib;
    inherit beamPackages;
    overrides = final: prev: {  };
  };

  # Uncomment if you have node dependencies.
  # nodeDependencies =
  #   (pkgs.callPackage "${src}/assets/default.nix" { }).shell.nodeDependencies;

  # ln -sf ${nodeDependencies}/lib/node_modules assets/node_modules
  postBuild = ''
    cp ${src}/_build/tailwind-linux-x64 _build/tailwind-linux-x64
    cp ${pkgs.esbuild}/bin/esbuild _build/esbuild-linux-x64
    mkdir -p ./deps/heroicons
    cp -r ${heroicons}/* ./deps/heroicons/

    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, assets.deploy
  '';
}
