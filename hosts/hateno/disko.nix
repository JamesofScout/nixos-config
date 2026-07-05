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
                  fast-persist = {
                    mountpoint = "/fast-persist";
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
      mass-storage1 = {
        device = "/dev/sda";
        content = {
          type = "luks";
          name = "m1";        
          settings.allowDiscards = true;
        };
      };
      mass-storage2 = {
        device = "/dev/sdb";
        content = {
          type = "luks";
          name = "m2";
          settings.allowDiscards = true;
        };
      };
      mass-storage3 = {
        device = "/dev/sdc";
        content = {
          type = "luks";
          name = "m3";
          settings.allowDiscards = true;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-d raid5" "/dev/mapper/m1" "/dev/mapper/m2" ];
            mountpoint = "/btrfs-roots/mass-storage";
            subvolumes = {
              mass-storage = {
                mountpoint = "/mass-storage";
              };
            };
          };
        };
      };
    };
  };
}
