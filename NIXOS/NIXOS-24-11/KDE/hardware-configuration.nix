# Do not modify this file! It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations. Please make changes
# to /etc/nixos/configuration.nix instead.

{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib;

let
  extraBackends = [ pkgs.epkowa ];
in

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "uas"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [
        "nvidia"
        "cifs"
      ]; # SMB protocol implementation.
    };
    systemd = {
        tpm2 = {
          enable = false;
        };
      };
      verbose = false;
    };
    supportedFilesystems = [
      "btrfs"
      "exfat"
      "ntfs"
    ];
    blacklistedKernelModules = lib.mkDefault [ "nouveau" ];
    kernelModules = [
      "kvm-intel"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ ];
    kernelParams = [
      "quiet"
      "mitigations=off"
      "nvidia_drm.fbdev=1"
      "nvidia_drm.modeset=1"
      "udev.log_level=3"
      "usbcore.autosuspend=-1"
    ];
    kernel.sysctl = {
      # Kernel Settings
      "kernel.pid_max" = 32768;                     # Default is 32768, adjusted for typical desktop use
      "kernel.pty.max" = 1024;                      # Default is typically enough for most desktop users
      "kernel.sched_autogroup_enabled" = 1;         # Enabled for better process grouping and user interactivity
      "kernel.sched_migration_cost_ns" = 5000000;   # Keep as is, balanced for desktop workloads
      "kernel.sysrq" = 1;                           # Keep enabled for troubleshooting purposes

      # Network Settings
      "net.core.default_qdisc" = "fq";              # fq (Fair Queue) is another great option for wireless; better for general use
      "net.core.netdev_max_backlog" = 10000;        # Default is usually 10000, adequate for desktop
      "net.core.rmem_default" = 4194304;            # Default is fine, adjusting to 4MB
      "net.core.rmem_max" = 16777216;               # Default value is fine for general desktop use
      "net.core.wmem_default" = 4194304;            # Default is fine, adjusting to 4MB
      "net.core.wmem_max" = 16777216;               # Default value is fine
      "net.ipv4.ipfrag_high_threshold" = 5242880;   # Default value is fine for general use
      "net.ipv4.tcp_congestion_control" = "bbr";    # BBR is a great option for modern networks
      "net.ipv4.tcp_keepalive_intvl" = 30;          # Default value is good, setting to 30 seconds for better keepalive
      "net.ipv4.tcp_keepalive_probes" = 5;          # Default value is good, setting to 5 probes
      "net.ipv4.tcp_keepalive_time" = 7200;         # Default value is good, keepalive interval set to 2 hours
      "net.ipv4.tcp_mtu_probing" = 1;               # Good for automatic MTU adjustments
      "net.ipv4.tcp_tw_reuse" = 1;                  # Reuse TIME-WAIT sockets for better performance
      "net.ipv4.udp_rmem_min" = 16384;              # Default value should be fine
      "net.ipv4.udp_wmem_min" = 16384;              # Default value should be fine

      # Virtual Memory Settings
      "vm.dirty_background_bytes" = 16777216;   # Slightly higher for SSD use (16MB)
      "vm.dirty_background_ratio" = 10;         # Keep it low to avoid unnecessary disk writes
      "vm.dirty_bytes" = 134217728;             # 128MB, balanced for desktop workloads
      "vm.dirty_expire_centisecs" = 500;        # Default value is generally good
      "vm.dirty_ratio" = 20;                    # Default 20% is generally fine for SSDs
      "vm.dirty_time" = 0;                      # Default 0ms
      "vm.dirty_writeback_centisecs" = 500;     # Default 500ms is fine for SSDs
      "vm.max_map_count" = 65530;               # Default is often fine unless using memory-heavy workloads
      "vm.min_free_kbytes" = 8192;              # Default is often sufficient for general use
      "vm.swappiness" = 1;                     # Keep low to avoid excessive swapping
      "vm.vfs_cache_pressure" = 100;            # Default value is fine, balancing file system cache

      # File System Settings
      "fs.aio-max-nr" = 1048576;                # Default should be fine for general use unless running heavy async I/O
      "fs.inotify.max_user_watches" = 524288;   # Sufficient for typical desktop use

      # Nobara Tweaks
      "kernel.panic" = 10;                      # Set a longer panic timeout (10 seconds) in case of system crash

    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/bfd5019f-8383-48f3-85d9-e6af194973e7";
      fsType = "ext4";
      options = [
        "data=ordered"
        "defaults"
        "discard"
        "noatime"
        "nodiratime"
        "relatime"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/952E-CC02";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "defaults"
        "nosuid"
        "nodev"
      ];
    };
  };

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "performance";
  };

  swapDevices = [ ];

  networking = {
    useDHCP = lib.mkDefault true;
  };

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  hardware = {
    bluetooth.powerOnBoot = false;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableAllFirmware = true;
    logitech.wireless.enable = true;
    logitech.wireless.enableGraphical = true;
    pulseaudio.enable = false;
    usb-modeswitch.enable = true;
    sane = {
      enable = true;
      extraBackends = extraBackends;
    };
  };
}