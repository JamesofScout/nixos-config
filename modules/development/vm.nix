{ config
, pkgs
, lib
, ...
}: {
  options.myprograms.development.vm.enable = lib.mkEnableOption "Enable Virt Manager";

  config = lib.mkIf config.myprograms.development.vm.enable {
    # Enable dconf (System Management Tool)
    programs.dconf.enable = true;

    # Install necessary packages
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      nmap
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
    ];

    # Manage the virtualisation services
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
        };
      };
      spiceUSBRedirection.enable = true;
    };
    services.spice-vdagentd.enable = true;
  };
}
