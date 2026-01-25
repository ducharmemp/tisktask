{ pkgs ? import <nixpkgs> { }, lib, appName, config, ... }:
with lib;
let
  cfg = config.services.${appName};
  workingDirectory = "/home/${appName}";
  phoenixService = "${appName}.service";
  migrationService = "${appName}_migration.service";

  # Use consistent beam package versions
  beamPackages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_28;

  postgresConfig = {
    enable = true;
    ensureDatabases = [ appName ];
    ensureUsers = [{
      name = appName;
      ensureDBOwnership = true;
    }];
  };

  firewallConfig = lib.mkIf cfg.openFirewall {
    allowedTCPPorts = [ cfg.port ];
  };

  tmpFilesRules = [
    "d ${workingDirectory}/uploads 0755 ${appName} uploads -"
  ];

  usersConfig = {
    "${appName}" = {
      isNormalUser = true;
      home = workingDirectory;
      extraGroups = [ "uploads" ];
      homeMode = "755";
    };
  };

  path = [ pkgs.bash ] ++ cfg.runtimePackages;

  environment = [
    "PHX_SERVER=true"
    "PHX_HOST=${cfg.host}"
    "DATABASE_SOCKET_DIR=/run/postgresql"
    "DATABASE_NAME=${appName}"
    "DATABASE_USER=${appName}"
    "PORT=${toString cfg.port}"
    "RELEASE_TMP='${workingDirectory}'"
    "RELEASE_COOKIE=${cfg.releaseCookie}"
  ];

  release = pkgs.callPackage ./package.nix {
    system = pkgs.stdenv.hostPlatform.system;
    inherit beamPackages;
    elixir = beamPackages.elixir_1_19;
    erlang = pkgs.erlang_28;
    hex = beamPackages.hex;
    mix2nix = pkgs.mix2nix.overrideAttrs {
      nativeBuildInputs = [ beamPackages.elixir_1_19 ];
      buildInputs = [ pkgs.erlang_28 ];
    };
  };

  servicesConfig = {
    "${appName}_migration" = {
      inherit path;
      unitConfig = {
        Description = "${appName} migrator";
        PartOf = [ phoenixService ];
        Requires = [ "postgresql.service" ];
        After = [ "postgresql.service" ];
      };
      serviceConfig = {
          ExecStart = ''
            ${release}/bin/${appName} eval "${cfg.migrateCommand}"
          '';
          User = appName;
          Group = "users";
          Type = "oneshot";
          WorkingDirectory = workingDirectory;
          Environment = environment;
          EnvironmentFile = cfg.environmentFile;
      };
    };

    "${appName}" = {
      inherit path;
      wantedBy = [ "multi-user.target" ];
      unitConfig = {
        Description = appName;
        Requires = [ migrationService ];
        After = [ migrationService ];
        StartLimitInterval = 10;
      };
      serviceConfig = {
          Type = "exec";
          ExecStart = "${release}/bin/${appName} start";
          ExecStop = "${release}/bin/${appName} stop";
          ExecReload = "${release}/bin/${appName} reload";
          User = appName;
          Group = "users";
          Restart = "on-failure";
          RestartSec = 5;
          StartLimitBurst = 3;
          WorkingDirectory = workingDirectory;
          Environment = environment;
          EnvironmentFile = cfg.environmentFile;
      };
    };
  };

in {
  options = with types; {
    enable = mkEnableOption "${appName} service";

    host = mkOption {
      type = str;
      description = "The host for this service";
    };

    port = mkOption {
      type = port;
      default = 4000;
      description = "The port on which this service will listen";
    };

    openFirewall = mkEnableOption "opening the firewall for TCP traffic on the service port";

    migrateCommand = mkOption {
      type = str;
      default = "Tisktask.Release.migrate";
      description = "The command to run when migrating the database";
    };

    runtimePackages = mkOption {
      type = listOf package;
      default = [];
      description = "The list of packages to include in the service";
    };

    environmentFile = mkOption {
      type = nullOr str;
      default = null;
      description = "Path to an environment file containing secrets (e.g., SECRET_KEY_BASE, RELEASE_COOKIE). Loaded by systemd.";
    };

    releaseCookie = mkOption {
      type = str;
      default = "YOUR_SUPER_SECRET_COOKIE_THAT_YOU_SHOULD_CHANGE";
      description = "Release cookie to use with Phoenix";
    };
  };

  services = servicesConfig;
  rules = tmpFilesRules;
  users = usersConfig;
  postgresql = postgresConfig;
  firewall = firewallConfig;
}
