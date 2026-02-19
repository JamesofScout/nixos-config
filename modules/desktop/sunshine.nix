{ lib, pkgs, config, ... }: {
  options.myprograms.desktop.sunshine = {
    enable = lib.mkEnableOption ''
      Enable Sunshine Remote Desktop Service
    '';
  };

  config = lib.mkIf (config.myprograms.desktop.sunshine.enable)
    {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = true;
      };
    };
}
