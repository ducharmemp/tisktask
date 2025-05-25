{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        basePackages = with pkgs; [beam.packages.erlang_27.elixir_1_17 beam.packages.erlang_27.erlang podman-compose watchman buildah postgresql jekyll];
        buildPackages = with pkgs; lib.optionals stdenv.hostPlatform.isLinux [inotify-tools virtiofsd] ++ lib.optionals stdenv.hostPlatform.isDarwin (with darwin.apple_sdk.frameworks; [CoreFoundation CoreServices]) ++ basePackages ++ [git docker-compose lexical tailwindcss esbuild];
        hooks = ''
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.hex-mix
          export MIX_PATH="${pkgs.beam.packages.erlang_27.hex}/lib/erlang/lib/hex/ebin"
          export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
          export ERL_AFLAGS="-kernel shell_history enabled"
        '';
      in
      with pkgs;
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = mkShell {
          buildInputs = buildPackages;
          shellHooks = hooks;
        };
      });
}
