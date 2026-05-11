{ pkgs, lib, ... }: {

  boot.kernelModules = [ "sg" ];

  nix-tun.storage.persist.subvolumes."arm" = {
    path = "/mass-storage/arm";
    directories = {
      "/home/arm/logs" = { owner = "arm"; group = "arm"; };
      "/home/arm/config" = { owner = "arm"; group = "arm"; };
      "/home/arm/logs/progress" = { owner = "arm"; group = "arm"; };
      "/home/arm/media/transcode" = { owner = "arm"; group = "arm"; };
      "/home/arm/media/completed" = { owner = "arm"; group = "arm"; };
      "/home/arm/media/raw" = { owner = "arm"; group = "arm"; };
    };
  };

  nix-tun.services.traefik.services."arm" = {
    servers = [
      "http://localhost:8080"
    ];
    router.rule = "Host(`arm.hatscript.de`)";
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.arm = {
      image = "ghcr.io/jamesofscout/arm-qsv:main";
      pull = "newer";
      ports = [
        "8080:8080"
      ];
      environment = {
        ARM_UID = "3333";
        ARM_GID = "3333";
      };
      volumes = [
        "/mass-storage/arm/home/arm:/home/arm"
        "/mass-storage/arm/home/arm/config:/etc/arm/config"
      ];
      devices = [
        "/dev/sr0:/dev/sr0"
        "/dev/sg0:/dev/sg0"
        "/dev/dri/renderD128"
        "/dev/dri/renderD129"
      ];
      privileged = true;
    };
  };

  users.users.arm = {
    uid = 3333;
    group = "arm";
    extraGroups = [ "cdrom" ];
    isNormalUser = true;
  };
  users.groups.arm = { gid = 3333; };

}
