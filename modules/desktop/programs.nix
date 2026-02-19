{ pkgs
, lib
, config
, ...
}: {
  options = {
    myprograms.desktop.programs.enable = lib.mkEnableOption "Enable Standard Desktop Programs";
  };

  imports = [
    ./firefox.nix
  ];

  config = lib.mkIf config.myprograms.desktop.programs.enable {
    myprograms.desktop.firefox.enable = true;
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
    services.flatpak.enable = true;
    environment.systemPackages = with pkgs; [
      onlyoffice-desktopeditors
      spotify
      bootstrap-studio
      element-desktop
      thunderbird
      streamcontroller
      gnome-boxes
      gnome-frog
      boatswain
      iotas
      wike
      impression
      hieroglyphic
    ];

  };
}
