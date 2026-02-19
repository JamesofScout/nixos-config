{ lib, config, pkgs, ... }: {
  options.myprograms.services.jellyfin = {
    enable = lib.mkEnableOption ''
      Enable Jellyfin streaming services
    '';
  };

  config = lib.mkIf config.myprograms.services.jellyfin.enable {
    services.jellyfin = {
      enable = true;
    };

    environment.systemPackages = with pkgs;[
      jellyfin
      jellyfin-web
      jellyfin-mpv-shim
    ];
  };
}
