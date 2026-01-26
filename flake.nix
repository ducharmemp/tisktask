{
  description = "Tisktask - CI/CD task orchestration platform";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "armv7l-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = {
        # NixOS module for the tisktask service
        nixosModules.tisktask =
          { config, lib, pkgs, ... }:
          let
            serviceLib = import ./nix/service.nix {
              inherit pkgs lib config;
              appName = "tisktask";
            };
          in
          {
            options.services.tisktask = serviceLib.options;

            config = lib.mkIf config.services.tisktask.enable {
              systemd.services = serviceLib.services;
              systemd.tmpfiles.rules = serviceLib.rules;
              users.users = serviceLib.users;
              services.postgresql = serviceLib.postgresql;
              networking.firewall = serviceLib.firewall;
              virtualisation.podman.enable = true;
              virtualisation.containers.registries.search = [ "docker.io" ];
            };
          };

        nixosModules.default = inputs.self.nixosModules.tisktask;

        # Overlay exposing the package and service module builder
        overlays.default = final: prev:
          let
            beamPackages = final.beam.packagesWith final.beam.interpreters.erlang_28;
          in {
          tisktask = final.callPackage ./nix/package.nix {
            system = final.stdenv.hostPlatform.system;
            inherit beamPackages;
            elixir = beamPackages.elixir_1_19;
            erlang = final.erlang_28;
            hex = beamPackages.hex;
            mix2nix = prev.mix2nix.overrideAttrs {
              nativeBuildInputs = [ beamPackages.elixir_1_19 ];
              buildInputs = [ final.erlang_28 ];
            };
          };

          tisktaskLib = {
            mkService =
              { appName ? "tisktask" }:
              { config, lib, pkgs, ... }:
              import ./nix/service.nix {
                inherit pkgs lib config appName;
              };
          };
        };
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          lib,
          ...
        }:
        let
          beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_28;
          elixir = beamPackages.elixir_1_19;
          erlang = pkgs.erlang_28;
          hex = beamPackages.hex;
          mix2nix = pkgs.mix2nix.overrideAttrs {
            nativeBuildInputs = [ elixir ];
            buildInputs = [ erlang ];
          };
          # Needed everywhere
          basePackages = with pkgs; [
            elixir
            erlang
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
          optionalPackages = lib.optionals pkgs.stdenv.isLinux [ pkgs.inotify-tools ];
        in
        {
          formatter = pkgs.writeShellApplication {
            name = "nixfmt-wrapper";

            runtimeInputs = [
              pkgs.fd
              pkgs.nixfmt-rfc-style
            ];

            text = ''
              fd "$@" -t f -e nix -x nixfmt '{}'
            '';
          };
          devShells.default = pkgs.mkShell {
            packages = basePackages ++ developerPackages ++ optionalPackages;
          };

          packages = {
            tisktask = pkgs.callPackage ./nix/package.nix {
              inherit
                system
                mix2nix
                beamPackages
                elixir
                erlang
                hex
                ;
            };
          };
        };
    };
}
