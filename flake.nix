{
  description = "My Phoenix application";

  inputs = {
    beam-flakes = {
      url = "github:elixir-tools/nix-beam-flakes";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      beam-flakes,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ beam-flakes.flakeModule ];

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { config, pkgs, ... }:
        let
          # Needed everywhere
          basePackages = with pkgs; [
            postgresql_17
            nodejs_24
          ];
          # Needed only on local machines
          developerPackages = with pkgs; [
            podman
            podman-compose
            watchman
            claude-code
            gemini-cli
            jq
            buildah
          ];
        in
        {
          beamWorkspace = {
            enable = true;
            devShell = {
              enable = true;
              extraPackages = basePackages ++ developerPackages;
            };
            versions = {
              fromToolVersions = ./.tool-versions;
            };
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
