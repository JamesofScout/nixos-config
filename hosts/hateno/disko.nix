{ ... }: {
  disko.devices = {
    disk = {
      boot = {
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountpoint = "/btrfs-roots/boot-disk";
                subvolumes = {
                  nix = {
                    mountpoint = "/nix";
                  };
                  fast_persistent = {
                    mountpoint = "/fast_persist";
                  };
                  root = {
                    mountpoint = "/";
                  };

                };
              };
            };
          };
        };
      };
      mass-storage = {
        device = "/dev/sda";
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];
          mountpoint = "/btrfs-roots/mass-storage";
          subvolumes = {
            big_persistent = {
              mountpoint = "/mass-storage";
            };
          };
        };
      };
    };
  };
}
