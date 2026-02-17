{ config
, pkgs
, lib
, ...
}: {
  options = {
    myservices.tailscale.enable = lib.mkEnableOption "Enable Tailscale";
  };

  config = lib.mkIf config.myservices.tailscale.enable {
    # always allow traffic from your Tailscale network
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # allow the Tailscale UDP port through the firewall
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

    # make the tailscale command usable to users
    environment.systemPackages = [ pkgs.tailscale ];

    # enable the tailscale service
    services.tailscale.enable = true;

    nix-tun.storage.persist.subvolumes."tailscale" = {
      bindMountDirectories = true;
      directories."/var/lib/tailscale/" = { };
    };

  };
}
