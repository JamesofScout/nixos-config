{ lib, pkgs, config, ... }: {
  options.myprograms.desktop.sunshine = {
    enable = lib.mkEnableOption ''
      Enable Sunshine Remote Desktop Service
    '';
    applications = lib.mkOption {
      type = lib.types.submodule {
        freeformType = (pkgs.formats.json { }).type;
      };
      default = {
        apps = [{
          name = "Desktop";
          image-path = "desktop.png";
        }];
      };
    };
  };

  config = lib.mkIf (config.myprograms.desktop.sunshine.enable)
    (
      let
        sunshine = pkgs.sunshine.override {
          cudaSupport = true;
          cudaPackages = pkgs.cudaPackages;
        };

        run-dir = "/run/user/1000";
        reset-resolution = pkgs.writeShellScript "reset-resolution.sh" ''
          #!/bin/bash
          # Called by Sunshine as an undo command when a client disconnects
          # Reset to default 1080p
          SWAYSOCK=${run-dir}/sway-sunshine.sock ${pkgs.sway}/bin/swaymsg \
              "output HEADLESS-1 mode 1920x1080@60Hz"
        '';
        restore-default-sink = pkgs.writeShellScript "restore-default-sink.sh" ''
          #!/bin/bash
          PATH=$PATH:${pkgs.gnugrep}/bin:${pkgs.coreutils-full}/bin:${pkgs.systemd}/bin:${pkgs.bash}/bin
          # Restores the host's default audio sink after Sunshine changes it.
          # Sunshine sets audio_sink as the system default when a client connects.
          # Uses systemd-run to spawn a detached watcher that survives prep-cmd cleanup.

          # Get the current default sink ID from wpctl
          # Format: " │  *   44. Komplete Audio 2 ..."
          SINK_ID=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | grep -A20 'Sinks:' | grep '\*' | head -1 | grep -oE '[0-9]+' | head -1)

          if [ -z "$SINK_ID" ]; then
              exit 0
          fi

          # Clean up any previous instance
          systemctl --user stop sunshine-sink-restore 2>/dev/null
          systemctl --user reset-failed sunshine-sink-restore 2>/dev/null

          # Launch a detached watcher via systemd-run (survives prep-cmd cleanup)
          systemd-run --user --no-block --unit=sunshine-sink-restore \
              ${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.coreutils-full}/bin/sleep 1; CUR=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | ${pkgs.gnugrep}/bin/grep -A20 "Sinks:" | ${pkgs.gnugrep}/bin/grep "\*" | ${pkgs.coreutils-full}/bin/head -1 | ${pkgs.gnugrep}/bin/grep -oE "[0-9]+" | ${pkgs.coreutils-full}/bin/head -1); if [ "$CUR" != "'"$SINK_ID"'" ] && [ -n "$CUR" ]; then ${pkgs.wireplumber}/bin/wpctl set-default '"$SINK_ID"'; exit 0; fi; done'
        '';
        set-resolution = pkgs.writeShellScript "set-resolution.sh" ''
          #!/bin/bash
          # Called by Sunshine as a prep command when a client connects
          # Dynamically sets the headless output to match the Moonlight client
          SWAYSOCK=${run-dir}/sway-sunshine.sock ${pkgs.sway}/bin/swaymsg \
              "output HEADLESS-1 mode $${SUNSHINE_CLIENT_WIDTH}x$${SUNSHINE_CLIENT_HEIGHT}@$${SUNSHINE_CLIENT_FPS}Hz"

          # Let the display mode settle before Sunshine starts capturing
          ${pkgs.coreutils-full}/bin/sleep 1
        '';
        start-steam-game = pkgs.writeShellScript "start-steam-game.sh" ''
          #!/bin/bash
          PATH=$PATH:${pkgs.gnugrep}/bin:${pkgs.toybox}/bin:${pkgs.systemd}/bin:${pkgs.wireplumber}/bin:${pkgs.steam}/bin:/run/current-system/sw/bin
          # Launches a Steam game in the headless Sway session
          # Usage: start-steam-game.sh <appid|bigpicture|0>
          # Migrates Steam from the main desktop if it's running there

          APPID="$1"
          SWAYSOCK="${run-dir}/sway-sunshine.sock"
          export SWAYSOCK

          if [ -z "$APPID" ]; then
              echo "Usage: $0 <steam_appid|bigpicture|0>"
              exit 1
          fi

          # Shut down any running Steam instance
          if pgrep -x steam > /dev/null 2>&1; then
              steam -shutdown 2>/dev/null
              # Wait for graceful shutdown
              for i in $(seq 1 15); do
                  pgrep -x steam > /dev/null 2>&1 || break
                  sleep 1
              done
              # Force kill only if still running
              if pgrep -x steam > /dev/null 2>&1; then
                  pkill -x steam 2>/dev/null
                  sleep 2
              fi
          fi

          # Clean up Steam IPC to prevent instance detection
          rm -f ~/.steam/steam.pid 2>/dev/null
          rm -f /tmp/steam_singleton_* 2>/dev/null

          # Launch Steam in the headless Sway session
          if [ "$APPID" = "bigpicture" ]; then
              ${pkgs.sway}/bin/swaymsg exec "${pkgs.steam}/bin/steam steam://open/bigpicture"
          elif [ "$APPID"= "0" ]; then
              ${pkgs.sway}/bin/swaymsg exec ${pkgs.steam}/bin/steam
          else
              ${pkgs.sway}/bin/swaymsg exec "${pkgs.steam}/bin/steam -applaunch $APPID"
          fi
        '';
        stop-steam-game = pkgs.writeShellScript "stop-steam-game.sh" ''
          #!/bin/bash
          PATH=$PATH:${pkgs.gnugrep}/bin:${pkgs.toybox}/bin:${pkgs.systemd}/bin:${pkgs.wireplumber}/bin:${pkgs.steam}/bin
          # Shuts down Steam in the headless session and restarts it on the main desktop

          # Shut down Steam in the headless session
          steam -shutdown 2>/dev/null

          # Wait for it to fully exit
          for i in $(seq 1 15); do
              pgrep -x steam > /dev/null 2>&1 || break
              sleep 1
          done

          # Force kill if still running
          if pgrep -x steam > /dev/null 2>&1; then
              pkill -x steam 2>/dev/null
              sleep 2
          fi

          # Clean up IPC
          rm -f ~/.steam/steam.pid 2>/dev/null
          rm -f /tmp/steam_singleton_* 2>/dev/null
        '';
        sunshine-apps = (pkgs.formats.json { }).generate "apps.json" config.myprograms.desktop.sunshine.applications;
        sunshine-config = pkgs.writeText "sunshine.conf" ''
          min_threads = 6
          audio_sink = null-sink-sunshine-stereo
          capture = wlr
          file_apps = ${sunshine-apps}
          global_prep_cmd = [{
              "do": "${restore-default-sink}",
              "undo": ""
            },{
            "do": "${set-resolution}",
            "undo": "${reset-resolution}"
            }
          ]
        '';
        sway-config = pkgs.writeText "sway.config" ''
          # Headless Sway session for Sunshine streaming
          # No physical display needed - uses WLR_BACKENDS=Headless
          # Default headless output - 1080p fallback, Sunshine prep commands override this
          output HEADLESS-1 resolution 1920x1080@60Hz

          # Performance tuning
          output * allow_tearing yes
          output * max_render_time off

          # Dark background
          exec ${pkgs.swaybg}/bin/swaybg -c '#FF1a2e'

          # Input isolation: disable all physical devices, enable only Sunshine virtual inputs
          # Sunshine passthrough devices use vendor 48879 (0xBEEF), product 57005 (0xDEAD)
          input * events disabled
          input "48879:57005:Keyboard_passthrough" events enabled
          input "48879:57005:Mouse_passthrough" events enabled
          input "48879:57005:Mouse_passthrough_(absolute)" events enabled
          input "48879:57005:Touch_passthrough" events enabled
          input "48879:57005:Pen_passthrough" events enabled
          input "1356:3302:Sunshine_PS5_(virtual)_pad_Touchpad" events enabled

          # Flat acceleration for mouse passthrough
          input "48879:57005:Mouse_passthrough" accel_profile flat
          input "48879:57005:Mouse_passthrough_(absolute)" accel_profile flat

          # Keybinding to launch a terminal (useful for debugging)
          bindsym Mod4+Return exec foot
        '';
        udev-rules = pkgs.writeTextFile {
          name = "85-sunshine-input-isolation.rules";
          destination = "/etc/udev/rules.d/85-sunshine-input-isolation.rules";
          text = ''
            # Tell Mutter/GNOME to ignore Sunshine virtual input devices.
            # Devices stay on seat0 so headless Sway's libinput can enumerate them.
            # This is GNOME-specific — Mutter checks this property before claiming a device.
            ACTION=="add|change", SUBSYSTEM=="input", ATTRS{id/vendor}=="beef", ATTRS{id/product}=="dead", ENV{mutter-device-ignore}="1"

            # Strip input capability from Sunshine virtual devices so KWin never sees them.
            # Devices remain accessible to headless Sway via libinput (which reads evdev directly).
            # This works by removing the ID_INPUT tags that KWin uses to discover input devices.
            # ACTION=="add|change", SUBSYSTEM=="input", ATTRS{id/vendor}=="beef", ATTRS{id/product}=="dead", ENV{ID_INPUT}="", ENV{ID_INPUT_KEYBOARD}="", ENV{ID_INPUT_MOUSE}="", ENV{ID_INPUT_TOUCHPAD}=""
            
          '';
        };
        sunshine-udev-rules = pkgs.writeTextFile {
          name = "60-sunshine.rules";
          destination = "/etc/udev/rules.d/60-sunshine.rules";
          text = ''
            # Allows Sunshine to acces /dev/uinput
            KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", GROUP="input", MODE="0660", TAG+="uaccess"

            # Allows Sunshine to access /dev/uhid
            KERNEL=="uhid", GROUP="input", MODE="0660", TAG+="uaccess"

            # Joypads
            KERNEL=="hidraw*", ATTRS{name}=="Sunshine PS5 (virtual) pad", GROUP="input", MODE="0660", TAG+="uaccess"
            SUBSYSTEMS=="input", ATTRS{name}=="Sunshine X-Box One (virtual) pad", GROUP="input", MODE="0660", TAG+="uaccess"
            SUBSYSTEMS=="input", ATTRS{name}=="Sunshine gamepad (virtual) motion sensors", GROUP="input", MODE="0660", TAG+="uaccess"
            SUBSYSTEMS=="input", ATTRS{name}=="Sunshine Nintendo (virtual) pad", GROUP="input", MODE="0660", TAG+="uaccess"
          '';
        };
      in
      {
        myprograms.desktop.sunshine.applications = {
          env = {
            SWAYSOCK = "${run-dir}/sway-sunshine.sock";
          };
          apps = [
            {
              name = "Desktop";
              image-path = "desktop.png";
            }
            {
              name = "Steam Big Picture";
              detached = [
                "${start-steam-game} bigpicture"
              ];
              prep-cmd = [
                {
                  do = "";
                  undo = "${stop-steam-game}";
                }
              ];
            }
            {
              name = "Spiderman";
              detached = [
                "${start-steam-game} 1817070"
              ];
              prep-cmd = [
                {
                  do = "";
                  undo = "${stop-steam-game}";
                }
              ];
            }
          ];
        };

        services.avahi = {
          publish = {
            enable = true;
            userServices = true;
          };
        };

        boot.kernelModules = [ "uhid" ];
        services.udev.packages = [ sunshine-udev-rules udev-rules ];
        security.wrappers.sunshine = {
          owner = "root";
          group = "root";
          capabilities = "cap_sys_admin+p";
          source = lib.getExe sunshine;
        };

        environment.systemPackages = with pkgs;
          [
            sway
            swaybg
            xdg-desktop-portal-wlr
            dbus
          ];

        networking.firewall = {
          allowedTCPPorts = [
            47984
            47989
            47990
            48010
          ];
          allowedUDPPorts = [
            47998
            47999
            48000
            48002
            48010
          ];
        };

        xdg.portal.wlr.enable = true;

        services.pipewire.extraConfig.pipewire."99-sunshine-null-sink"."context.objects" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "null-sink-sunshine-stereo";
              "node.description" = "Sunshine Streaming Sink (Stereo)";
              "media.class" = "Audio/Sink";
              "audio.position" = [ "FL" "FR" ];
              "monitor.channel-volumes" = true;
            };
          }
        ];

        systemd.user.services.sunshine-headless = {
          unitConfig = {
            Description = "Sunshine streaming via headless Sway";
            After = "sway-sunshine.service";
            Requires = "sway-sunshine.service";
          };
          serviceConfig = {
            #User = "florian";
            #Group = "input";
            Type = "simple";
            Environment = [
              "WAYLAND_DISPLAY=wayland-1"
              "SWAYSOCK=${run-dir}/sway-sunshine.sock"
              "XDG_SESSION_TYPE=wayland"
              "XDG_CURRENT_DESKTOP=sway"
              "XDG_RUNTIME_DIR=${run-dir}"
              "PATH=${pkgs.xdg-desktop-portal-wlr}/bin:${pkgs.pipewire}/bin:${pkgs.wireplumber}/bin:${pkgs.cairo}/bin"
            ];
            ExecStartPre = "${pkgs.coreutils-full}/bin/sleep 2";
            ExecStart = "${config.security.wrapperDir}/sunshine ${sunshine-config}";
            Restart = "on-failure";
            RestartSec = 5;
          };
          wantedBy = [ "default.target" ];
        };

        systemd.user.services.sway-sunshine = {
          unitConfig = {
            Description = "Headless Sway session for Sunshine streaming";
            After = "graphical-session.target";
          };
          serviceConfig = {
            Type = "simple";
            #User = "florian";
            #Group = "input";
            Environment = [
              "WLR_BACKENDS=headless,libinput"
              "LIBSEAT_BACKEND=noop"
              "WLR_LIBINPUT_NO_DEVICES=1"
              "WLR_RENDERER=gles2"
              "XDG_RUNTIME_DIR=${run-dir}"
              "XDG_SESSION_TYPE=wayland"
              "XDG_CURRENT_DESKTOP=sway"
              "SWAYSOCK=${run-dir}/sway-sunshine.sock"
              "PULSE_SINK=null-sink-sunshine-stereo"
              "PATH=$PATH:${pkgs.dbus}/bin:/bin:${pkgs.pipewire}/bin:${pkgs.wireplumber}/bin:${pkgs.sway}/bin"
            ];
            ExecStartPre = "${pkgs.coreutils-full}/bin/rm -f ${run-dir}/sway-sunshine.sock";
            ExecStart = "${config.security.wrapperDir}/sg input -c '${pkgs.sway}/bin/sway --unsupported-gpu --config ${sway-config}'";
            Restart = "on-failure";
            RestartSec = 5;
          };
          wantedBy = [ "default.target" ];
        };

        hardware.uinput.enable = true;
      }
    );
}
