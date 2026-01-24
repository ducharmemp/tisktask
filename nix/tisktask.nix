{
  lib,
  pkgs,
  beamPackages,
  nodejs,
  esbuild,
  tailwindcss,
  git,
  podman,
  buildah,
  makeWrapper,
}:

let
  # beam.interpreters.erlang_26 is available if you need a particular version
  packages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_28;

  pname = "tisktask";
  version = "0.0.1";

  src = lib.cleanSource ../.;

  mixFodDeps = packages.fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version;
    hash = "sha256-1XnrQJRd7ssF93NGtzVfkoB9M4eewKugJGkpvINHpvY=";
    mixEnv = "prod";
    MY_ENV_VAR = "my_value";
  };
in
packages.mixRelease {
  inherit
    src
    pname
    version
    mixFodDeps
    ;

  nativeBuildInputs = [
    makeWrapper
  ];

  # Environment for production build
  MIX_ENV = "prod";

  preConfigure = ''
    rm -rf deps _build
  '';

  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';

  # Install and create wrapper
  postInstall = ''
    # Create a wrapper script for easier execution
    mkdir -p $out/bin
    makeWrapper $out/bin/tisktask $out/bin/tisktask-server \
      --set MIX_ENV prod \
      --set PHX_SERVER true
  '';
}
