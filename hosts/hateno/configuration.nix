# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  myprograms = {
    cli.better-tools.enable = true;
    cli.nixvim.enable = true;
  };

  fileSystems."/fast_persist".neededForBoot = true;

  nix-tun.storage.persist = {
    enable = true;
    path = "/fast_persist";
    subvolumes = {
      "containers/jellyfin".path = "/mass-storage/containers/jellyfin";
    };
  };

  imports = [
    ./disko.nix
  ];

  nix-tun.services.traefik = {
    enable = true;
    letsencryptMail = "florian.schubert.sg@gmail.com";
  };
  nix-tun.alloy.prometheus-host = null;
  nix-tun.services.containers.nextcloud.secretsFile = {
    enable = true;
    hostname = "nextcloud.hatscript.de";
  };

  nix-tun.utils.containers.jellyfin = {
    domains.jellyfin = {
      domain = "jellyfin.hatscript.de";
      port = 8096;
    };
    volumes = {
      "/var/cache/jellyfin" = { };
      "/var/lib/jellyfin" = { };
      "/media" = { owner = "jellyfin"; group = "jellyfin"; };
      "/books" = { owner = "jellyfin"; group = "jellyfin"; };
      "/cache" = { owner = "jellyfin"; group = "jellyfin"; };
    };
    config = { ... }: {
      environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
      ];

      services.jellyfin = {
        enable = true;
        transcoding.enableHardwareEncoding = true;
      };
    };
  };


  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Hateno"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  systemd.network.enable = true;

  services.resolved.enable = true;
  sops.useTmpfs = true;
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Define a user account. Don't forget to set a password with ‘passwd’.

  sops = {
    defaultSopsFormat = "yaml";
    defaultSopsFile = ../../secrets/hateno.yaml;
  };
  sops.secrets.florian-pass = {
    format = "yaml";
    sopsFile = ../../secrets/florian.yaml;
    neededForUsers = true;
  };

  sops.secrets.cloudflare-apitoken = {
    format = "yaml";
    sopsFile = ../../secrets/cloudflare-apitoken.yaml;
  };

  users.users.florian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    uid = 1000;
    group = "florian";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqlr0nKMcn6rZE0hn8RyzfgT75IxKwzgPn59WH1TSdskJNwRJh5UEDKtHA3eSxguWVdJqSDtbDeO7D6pofqPxMarhCoQwa79056e2LtDYVrABTQPabRSTreHDbMekj6RsxdHAg2BFayutEVwHHRKBuyK3DQd5hu4P3DM9t3c5Zd4XEUY4wB0N2EYy56/kw7uUM49dCX10GLSFVivVyUmb3IpFLmOt7s5I64JpsU5NGG4VdrsRJlG2U2q8f3PWf8tIhqONtR+wa7AYOKKGmBBuq7I1qX3lE7+sgxUc9CFfHVC8+OLclnCizlJaiqXIN+K35URyrqxY5Wf7POeSfhewB florian@yubikey"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDF5vhkEdRPrHHLgCMxm0oSrHU+uPM9W45Kdd/BKGreRp5vAA70vG3xEjzGdzIlhF0/qOZisA3MpjnMhW3l+uogTzuD3vDZdgT/pgoZEy2CIGIp9kbK5pQHhEhMbWi5NS5o8F095ZZRjBwRE1le9GmBZbYj3VUHSVaRxv+gZpSdqKBo9Arvr4L/lyTdpYgGEHUParWX+UtkBXSd0mO91h6XM8hEqLJv+ufbgA4az0O8sNTz2Uh+k3kN2sQn11O3ekGk4M9fpDP9+C17C9fbMpMATbFazl5pWnPqgLPrvNCs8dkKEJCRPgTgXHYaOppZ7hprJvMpOYW/IYyYo/1T2j6ELZJ7apMJNlOhWqVDnM5DGSIf65oNGZLiAupq1X+s6IoSEZOcAuWfTlJgRySdNgh/BSiKvmKG0nK8/z2ERN0/shE9/FT7pMyEfxHzNdl4PMvpPKZkucX1z4Pb3DtR684WRxD94lj5Nqh/3CH0EeLMJPwyFsOBNdsitqZGLHpGbOLZ3VDdjbOl2Qjgyl/VwzhAWNYUpyxZj3ZpFlHyDE0y38idXG7L0679THKzE62ZAnPdHHTP5RdWtRUqpPyO/nVXErOr8j55oO27C6jD0n5L4tU3QgSpjMOvomk9hbPzKEEuDGG++gSj9JoVHyAMtkWiYuamxR1UY1PlYBskC/q77Q== openpgp:0xB802445D"
    ];
  };
  users.groups.florian.gid = 1000;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  security.pam.sshAgentAuth.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.enable = true;

  services.cloudflare-dyndns = {
    enable = true;
    ipv4 = true;
    ipv6 = true;
    domains = [
      "hatscript.de"
      "*.hatscript.de"
    ];
    apiTokenFile = config.sops.secrets.cloudflare-apitoken.path;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
