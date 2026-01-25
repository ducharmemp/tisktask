{
  pkgs ? import <nixpkgs> { },
  system,
  nodejs,
  beamPackages,
  elixir,
  erlang,
  hex,
  mix2nix,
  port ? 4000
}:
let
  pname = "tisktask";
  version = "0.1.0";
  translatedPlatform =
    {
      aarch64-darwin = "macos-arm64";
      aarch64-linux = "linux-arm64";
      armv7l-linux = "linux-armv7";
      x86_64-darwin = "macos-x64";
      x86_64-linux = "linux-x64";
    }
    .${system};
  src = ../.;
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
  mixFodDeps = beamPackages.fetchMixDeps {
    inherit version src;
    pname = "${pname}-elixir-deps";
    sha256 = "sha256-WpAnvGDVbKm6ItkdOjEQetHBKSdzz6PJT24/Cj3Fpus";
  };
in
 beamPackages.mixRelease {
    inherit
      version
      src
      mixFodDeps
      pname
      ;

    buildInputs = [elixir erlang];

    removeCookie = false;
    nativeBuildInputs = with pkgs; [ esbuild tailwindcss_3 ];
    erlangDeterministicBuilds = false;

    PORT = "${toString (port)}";
    RELEASE_COOKIE = "SUPER_SECRET_SECRET_COOKIE";
    SECRET_KEY_BASE = "SUPER_SECRET_SECRET_KEYBASE";

    # Explicitly declare tailwind and esbuild binary paths (don't let Mix fetch them)
    preConfigure = ''
      substituteInPlace config/config.exs \
        --replace "config :tailwind," "config :tailwind, path: \"${pkgs.tailwindcss_4}/bin/tailwindcss\","\
        --replace "config :esbuild," "config :esbuild, path: \"${pkgs.esbuild}/bin/esbuild\", "

      mkdir -p $MIX_DEPS_PATH/heroicons
      cp -r ${heroicons}/* $MIX_DEPS_PATH/heroicons/
    '';

    postBuild = ''
      # for external task you need a workaround for the no deps check flag
      # https://github.com/phoenixframework/phoenix/issues/2690
      mix do deps.loadpaths --no-deps-check, assets.deploy
    '';

    preInstall = ''
      mix do deps.loadpaths --no-deps-check, phx.gen.release
    '';
  }
