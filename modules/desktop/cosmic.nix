{ config
, pkgs
, lib
, ...
}: {
  options = {
    myprograms.desktop.cosmic.enable = lib.mkEnableOption "Enable Cosmic desktop";
  };

  config = lib.mkIf config.myprograms.desktop.cosmic.enable {

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    desktop.programs.enable = true;
  };
}
