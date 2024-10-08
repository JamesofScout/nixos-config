# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    ../../fonts.nix
    ../../modules/modules.nix
  ];

  nix-tun.storage.persist = {
    enable = true;
    subvolumes = {
      "home" = {
        bindMountDirectories = true;
        directories = {
          "/home/florian" = {
            owner = "florian";
            group = "florian";
            mode = "0700";
          };
        };
      };
    };
  };
  nix-tun.yubikey-gpg.enable = true;
  myservices = {
    tailscale.enable = true;
  };

  myprograms = {
    #desktop.gnome.enable = true;
    desktop.programs.enable = true;
    cli.better-tools.enable = true;
    cli.nixvim.enable = true;
  };

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  services = {
    fprintd.enable = false;
    pipewire.enable = true;
    pipewire.audio.enable = true;
    pipewire.alsa.enable = true;
    pipewire.pulse.enable = true;
  };

  services.mpd = {
    enable = true;
    startWhenNeeded = true;
  };

  nixpkgs.config.allowUnfree = true;

  hardware.bluetooth.enable = true;
  programs.nano.enable = false;

  services.blueman.enable = true;

  # Networking
  networking.firewall.enable = true;
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  systemd.network.enable = true;
  services.tailscale.enable = true;
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    keyMap = "us";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.epson-escpr
    pkgs.epson-escpr2
  ];

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  # for a WiFi printer
  virtualisation.libvirtd.enable = true;
  services.avahi.openFirewall = true;

  sops.secrets.florian-pass = {
    format = "yaml";
    sopsFile = ../../secrets/florian.yaml;
    neededForUsers = true;
  };

  # User Account
  users.users.florian = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.florian-pass.path;
    extraGroups = ["wheel" "networkmanager" "uinput" "input" "docker"];
    shell = pkgs.fish;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.florian = import ../../home/florian.nix;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    sox
    solaar
    wireguard-tools
  ];

  services.openssh.hostKeys = [
    {
      bits = 4096;
      openSSHFormat = true;
      path = "/persist/ssh-keys/ssh_host_rsa_key";
      rounds = 100;
      type = "rsa";
    }
    {
      comment = "key comment";
      path = "/persist/ssh-keys/ssh_host_ed25519_key";
      rounds = 100;
      type = "ed25519";
    }
  ];

  programs.ssh.extraConfig = ''
  Host *
    ForwardAgent yes
  '';

  programs.java.enable = true;
  programs.java.package = pkgs.jdk21;

  # List services that you want to enable:
  services.udev.packages = [pkgs.yubikey-personalization];
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.10"; # Did you read the comment?

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
}
