{ lib
, inputs
, ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./cli/better-tools.nix
    ./cli/nixvim.nix
    ./desktop/gnome.nix
    ./desktop/hyprland.nix
    ./development/vm.nix
    ./desktop/programs.nix
    ./desktop/sunshine.nix
    ./services/tailscale.nix
    ./stylix.nix
    #./impermanence.nix
    ./yubikey-gpg.nix
  ];

  myprograms.stylix.enable = lib.mkDefault true;
  myprograms.cli.better-tools.enable = lib.mkDefault true;
}
