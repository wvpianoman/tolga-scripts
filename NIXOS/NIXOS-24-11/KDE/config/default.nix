{ config, pkgs, ... }:

{
  imports = [
    ./boot
    ./modules
    ./modules
    ./system

    # ---- Desktop Environment ---- #
    ./desktop-environments

    # ---- OUT OF SERVICE ---- # 
    #./enviroment-sessions   
    #./packages
    #./tweaks
    # ./tmpfs
    # ./user
    # ./zram
  ];
}

# sudo chown -R $(whoami):$(id -gn) /etc/nixos && sudo chmod -R 777 /etc/nixos && sudo chmod +x /etc/nixos/* && export NIXPKGS_ALLOW_INSECURE=1

