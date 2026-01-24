{
  config,
  pkgs,
  lib,
  ...
}:

let
  release = pkgs.callPackage ./default.nix;
  release_name = "app";
  working_directory = "/home/app";
in
{
  systemd.services.${release_name} = {
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.target"
    ];
    # note that if you are connecting to a postgres instance on a different host
    # postgresql.target should not be included in the requires.
    requires = [
      "network-online.target"
      "postgresql.target"
    ];
    description = "my app";
    environment = {
      # RELEASE_TMP is used to write the state of the
      # VM configuration when the system is running
      # it needs to be a writable directory
      RELEASE_TMP = working_directory;
      # can be generated in an elixir console with
      # Base.encode32(:crypto.strong_rand_bytes(32))
      RELEASE_COOKIE = "my_cookie";
      MY_VAR = "my_var";
    };
    serviceConfig = {
      Type = "exec";
      DynamicUser = true;
      WorkingDirectory = working_directory;
      # Implied by DynamicUser, but just to emphasize due to RELEASE_TMP
      PrivateTmp = true;
      ExecStart = ''
        ${release}/bin/${release_name} start
      '';
      ExecStop = ''
        ${release}/bin/${release_name} stop
      '';
      ExecReload = ''
        ${release}/bin/${release_name} restart
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitInterval = 10;
    };
    # disksup requires bash
    path = [ pkgs.bash ];
  };

  # in case you have migration scripts or you want to use a remote shell
  environment.systemPackages = [ release ];
}
