{
  description = "Tisktask - CI/CD task orchestration platform";

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
      self,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ beam-flakes.flakeModule ];

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      flake = {
        # NixOS module for deploying Tisktask as a service
        nixosModules = {
          default = self.nixosModules.tisktask;
          tisktask = import ./nix/module.nix;
        };
      };

      perSystem =
        { config, pkgs, system, ... }:
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

          packages = {
            tisktask = pkgs.callPackage ./nix/package.nix { };
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
