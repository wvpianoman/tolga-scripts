#!/bin/bash

# Tolga Erok.
# My personal Fedora 39 KDE tweaker
# 18/11/2023

# Run from remote location:::.
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolgaerok/tolga-scripts/main/Fedora39/TolgaFedora39.sh)"

#  ¯\_(ツ)_/¯
#    █████▒▓█████ ▓█████▄  ▒█████   ██▀███   ▄▄▄
#  ▓██   ▒ ▓█   ▀ ▒██▀ ██▌▒██▒  ██▒▓██ ▒ ██▒▒████▄
#  ▒████ ░ ▒███   ░██   █▌▒██░  ██▒▓██ ░▄█ ▒▒██  ▀█▄
#  ░▓█▒  ░ ▒▓█  ▄ ░▓█▄   ▌▒██   ██░▒██▀▀█▄  ░██▄▄▄▄██
#  ░▒█░    ░▒████▒░▒████▓ ░ ████▓▒░░██▓ ▒██▒ ▓█   ▓██▒
#   ▒ ░    ░░ ▒░ ░ ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░
#   ░       ░ ░  ░ ░ ▒  ▒   ░ ▒ ▒░   ░▒ ░ ▒░  ▒   ▒▒ ░
#   ░ ░       ░    ░ ░  ░ ░ ░ ░ ▒    ░░   ░   ░   ▒
#   ░  ░      ░    ░ ░     ░              ░  ░   ░

clear

# Assign a color variable based on the RANDOM number
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
ORANGE='\e[1;93m'
NC='\e[0m'


# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Function to display messages
display_message() {
    clear
    echo -e "\n                  Tolga's online fedora updater\n"
    echo -e "\e[34m|--------------------\e[33m Currently configuring:\e[34m-------------------|"
    echo -e "|      ===>    $1"
    echo -e "\e[34m|--------------------------------------------------------------|\e[0m"
    echo ""
    sleep 1
}

# Function to check and display errors
check_error() {
    if [ $? -ne 0 ]; then
        display_message "Error occurred. Exiting."
        # Print the error details
        echo "Error details: $1"
        exit 1
    fi
}

# Function to configure faster updates in DNF
configure_dnf() {
    # Define the path to the DNF configuration file
    DNF_CONF_PATH="/etc/dnf/dnf.conf"

    display_message "Configuring faster updates in DNF..."

    # Check if the file exists before attempting to edit it
    if [ -e "$DNF_CONF_PATH" ]; then
        # Backup the original configuration file
        sudo cp "$DNF_CONF_PATH" "$DNF_CONF_PATH.bak"

        # Use sudo to edit the DNF configuration file with nano
        sudo nano "$DNF_CONF_PATH" <<EOL
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=1
max_parallel_downloads=10
deltarpm=true
metadata_timer_sync=0
metadata_expire=6h
metadata_expire_filter=repo:base:2h
metadata_expire_filter=repo:updates:12h
EOL

        # Inform the user that the update is complete
        display_message "DNF configuration updated for faster updates."
        sudo dnf install -y fedora-workstation-repositories
        sudo dnf update && sudo dnf makecache
    else
        # Inform the user that the configuration file doesn't exist
        display_message "Error: DNF configuration file not found at $DNF_CONF_PATH."
    fi

}

# Install new dnf5
dnf5() {
    # Ask the user if they want to install dnf5
    display_message "Beta: DNF5 for fedora 40/41 testing"
    read -p "Do you want to install dnf5? (y/n): " install_dnf5
    if [[ $install_dnf5 =~ ^[Yy]$ ]]; then
        sudo dnf install dnf5 -y
        sudo dnf5 update && sudo dnf5 makecache

        echo "In order to use dnf, you need to use sudo dnf5 update"
    else
        echo "Aborted installation of dnf5. Returning to the main menu."
    fi

}

# Change Hostname
change_hotname() {
    current_hostname=$(hostname)

    display_message "Changing HOSTNAME: $current_hostname"

    # Get the new hostname from the user
    read -p "Enter the new hostname: " new_hostname

    # Change the system hostname
    sudo hostnamectl set-hostname "$new_hostname"

    # Update /etc/hosts file
    sudo sed -i "s/127.0.0.1.*localhost/127.0.0.1 $new_hostname localhost/" /etc/hosts

    # Display the new hostname
    echo "Hostname changed to: $new_hostname"
    sleep 2
}
# Function to install RPM Fusion
install_rpmfusion() {
    display_message "Installing RPM Fusion repositories..."

    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    sudo dnf groupupdate core

    check_error

    display_message "RPM Fusion installed successfully."
}

# Function to update the system
update_system() {
    display_message "Updating the system...."

    sudo dnf update -y

    # Install necessary dependencies if not already installed
    display_message "Checking for extra dependencies..."
    sudo dnf install -y rpmconf

    # Install DNF plugins core (if not already installed)
    sudo dnf install -y dnf-plugins-core

    # Install required dependencies
    # sudo dnf install -y epel-release
    sudo dnf install -y dnf-plugins-core

    # Update the package manager
    sudo dnf makecache -y
    sudo dnf upgrade -y --refresh

    check_error

    display_message "System updated successfully."
}

# Function to install firmware updates with a countdown on error
install_firmware() {
    display_message "Installing firmware updates..."

    # Attempt to install firmware updates
    sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update

    # Check for errors during firmware updates
    if [ $? -ne 0 ]; then
        display_message "Error occurred during firmware updates.."

        # Countdown for 10 seconds on error
        for i in {4..1}; do
            echo -ne "Continuing in $i seconds... \r"
            sleep 1
        done
        echo -e "Continuing with the script."
    else
        display_message "Firmware updated successfully."
    fi
}

# Function to install GPU drivers with a reboot option on a 3 min timer, Nvidia && AMD
install_gpu_drivers() {
    display_message "Checking GPU and installing drivers..."

    # Check for NVIDIA GPU
    if lspci | grep -i nvidia &>/dev/null; then
        display_message "NVIDIA GPU detected. Installing NVIDIA drivers..."

        sudo dnf update
        sudo dnf install dnf-plugins-core -y
        sudo dnf copr enable t0xic0der/nvidia-auto-installer-for-fedora -y
        sudo dnf install nvautoinstall -y

        # Install some dependencies
        sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig

        # inntf
        # echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

        sudo sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ rd.driver.blacklist=nouveau modprobe.blacklist=nouveau nvidia-drm.modeset=1"/' /etc/default/grub

        # remove mouveau
        sudo dnf remove -y xorg-x11-drv-nouveau

        # Backup old initramfs nouveau image #
        sudo mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img

        # Create new initramfs image #
        sudo dracut /boot/initramfs-$(uname -r).img $(uname -r)

        sudo dnf install -y akmod-nvidia
        sudo systemctl disable --now fwupd-refresh.timer
        sudo dnf repolist | grep 'rpmfusion-nonfree-updates'
        sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf config-manager --set-enabled rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates

        sudo dnf install -y kernel-devel akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs gcc kernel-headers xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs
        sudo dnf install -y vdpauinfo libva-vdpau-driver libva-utils vulkan akmods
        sudo dnf install -y nvidia-settings nvidia-persistenced
        sudo akmods --force
        sudo sudo nvautoinstall rpmadd
        sudo nvautoinstall driver
        sudo nvautoinstall nvrepo
        sudo nvautoinstall plcuda
        sudo nvautoinstall ffmpeg
        sudo nvautoinstall vulkan
        sudo nvautoinstall vidacc
        sudo nvautoinstall compat
        sleep 1

        # sudo dracut -f
        # sudo dracut --force
        # sudo dnf remove xorg-x11-drv-nvidia\*
        # sudo dnf install xrandr
        # sudo systemctl start nvidia-powerd.service
        # sudo systemctl status nvidia-powerd.service

        display_message "Enabling nvidia-modeset..."

        # Enable nvidia-modeset
        sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"

        display_message "nvidia-modeset enabled successfully."

        driver_version=$(modinfo -F version nvidia 2>/dev/null)

        if [ -n "$driver_version" ]; then
            display_message "NVIDIA driver version: $driver_version"
            sleep 1
        else
            display_message "NVIDIA driver not found."
        fi

        sleep 2

        check_error "Failed to install NVIDIA drivers."
        display_message "NVIDIA drivers installed successfully."
    fi

    # Check for AMD GPU
    if lspci | grep -i amd &>/dev/null; then
        display_message "AMD GPU detected. Installing AMD drivers..."

        sudo dnf install -y mesa-dri-drivers

        check_error "Failed to install AMD drivers."
        display_message "AMD drivers installed successfully."
    fi

    # Prompt user for reboot or continue
    read -p "Do you want to reboot now? (y/n): " choice
    case "$choice" in
    y | Y)
        # Reboot the system after 3 minutes
        display_message "Rebooting in 3 minutes. Press Ctrl+C to cancel."
        sleep 180
        sudo reboot
        ;;
    n | N)
        display_message "Reboot skipped. Continuing with the script."
        ;;
    *)
        display_message "Invalid choice. Continuing with the script."
        ;;
    esac
}

# Function to optimize battery life on lappy, in theory.... LOL
optimize_battery() {
    display_message "Optimizing battery life..."

    # Check if the battery exists
    if [ -e "/sys/class/power_supply/BAT0" ]; then
        # Install TLP and mask power-profiles-daemon
        sudo dnf install -y tlp tlp-rdw
        sudo systemctl mask power-profiles-daemon

        # Install powertop and apply auto-tune
        sudo dnf install -y powertop
        sudo powertop --auto-tune

        display_message "Battery optimization completed."
    else
        display_message "No battery found. Skipping battery optimization."
    fi
}

# Function to install multimedia codecs, old fedora hacks to meet new standards (F39)
install_multimedia_codecs() {
    display_message "Installing multimedia codecs..."

    sudo dnf groupupdate 'core' 'multimedia' 'sound-and-video' --setopt='install_weak_deps=False' --exclude='PackageKit-gstreamer-plugin' --allowerasing && sync
    sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
    sudo dnf install -y lame\* --exclude=lame-devel
    sudo dnf group upgrade --with-optional Multimedia

    # Enable support for Cisco OpenH264 codec
    sudo dnf config-manager --set-enabled fedora-cisco-openh264 -y
    sudo dnf install gstreamer1-plugin-openh264 mozilla-openh264 -y

    display_message "Multimedia codecs installed successfully."
}

# Function to install H/W Video Acceleration for AMD or Intel chipset
install_hw_video_acceleration_amd_or_intel() {
    display_message "Checking for AMD chipset..."

    # Check for AMD chipset
    if lspci | grep -i amd &>/dev/null; then
        display_message "AMD chipset detected. Installing AMD video acceleration..."

        sudo dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld
        sudo dnf config-manager --set-enabled fedora-cisco-openh264
        sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

        display_message "H/W Video Acceleration for AMD chipset installed successfully."
    else
        display_message "No AMD chipset found. Pausing for user confirmation..."

        # Pause for user confirmation
        read -p "Press Enter to check for Intel chipset..."

        display_message "Checking for Intel chipset..."

        # Check for Intel chipset
        if lspci | grep -i intel &>/dev/null; then
            display_message "Intel chipset detected. Installing Intel video acceleration..."

            sudo dnf install -y intel-media-driver

            # Install video acceleration packages
            sudo dnf install libva libva-utils xorg-x11-drv-intel -y

            display_message "H/W Video Acceleration for Intel chipset installed successfully."
        else
            display_message "No Intel chipset found. Skipping H/W Video Acceleration installation."
        fi
    fi
}

# Function to clean up old or unused Flatpak packages
cleanup_flatpak_cruft() {
    display_message "Cleaning up old or unused Flatpak packages..."

    # Remove uninstalled runtimes
    flatpak uninstall --unused -y

    # Remove uninstalled applications
    flatpak uninstall --unused -y --delete-data

    display_message "Flatpak cleanup completed."
}

# Function to update Flatpak
update_flatpak() {
    display_message "Updating Flatpak..."

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # flatpak update
    flatpak update --refresh

    display_message "Executing Tolga's Flatpak's..."
    # Execute the Flatpak Apps installation script from the given URL
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolgaerok/tolga-scripts/main/Fedora39/FlatPakApps.sh)"

    display_message "Flatpak updated successfully."

    # Call the cleanup function
    cleanup_flatpak_cruft
}

# Function to set UTC Time for dual boot issues, old hack of mine
set_utc_time() {
    display_message "Setting UTC Time..."

    sudo timedatectl set-local-rtc '0'

    display_message "UTC Time set successfully."
}

# Function to disable mitigations, old fedora hack and used on nixos also, thanks chris titus!
disable_mitigations() {
    display_message "Disabling Mitigations..."

    # Inform the user about the security risks
    display_message "Note: Disabling mitigations can present security risks. Only proceed if you understand the implications."

    # Ask for user confirmation
    read -p "Do you want to proceed? (y/n): " choice
    case "$choice" in
    y | Y)
        # Disable mitigations
        sudo grubby --update-kernel=ALL --args="mitigations=off"
        display_message "Mitigations disabled successfully."
        ;;
    n | N)
        display_message "Mitigations not disabled. Exiting."
        exit 1
        ;;
    *)
        display_message "Invalid choice. Exiting."
        exit 1
        ;;
    esac
}

# Function to enable Modern Standby. Can result in better battery life when your laptop goes to sleep.... in theory LOL
enable_modern_standby() {
    display_message "Enabling Modern Standby..."

    # Enable Modern Standby
    sudo grubby --update-kernel=ALL --args="mem_sleep_default=s2idle"

    display_message "Modern Standby enabled successfully."
}

# Function to enable nvidia-modeset
enable_nvidia_modeset() {
    display_message "Enabling nvidia-modeset..."

    # Enable nvidia-modeset
    sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"

    display_message "nvidia-modeset enabled successfully."
}

# Function to disable NetworkManager-wait-online.service
disable_network_manager_wait_online() {
    display_message "Disabling NetworkManager-wait-online.service..."

    # Disable NetworkManager-wait-online.service
    sudo systemctl disable NetworkManager-wait-online.service

    display_message "NetworkManager-wait-online.service disabled successfully."
}

# Function to disable Gnome Software from Startup Apps, if gnome is used... in theory will save heaps of RAM on startup
disable_gnome_software_startup() {
    display_message "Disabling Gnome Software from Startup Apps..."

    # Remove Gnome Software from autostart
    sudo rm /etc/xdg/autostart/org.gnome.Software.desktop

    display_message "Gnome Software disabled from Startup Apps successfully."
}

# Function to use themes in Flatpaks, learned from nixos and trials and errors...
use_flatpak_themes() {
    display_message "Using themes in Flatpaks..."

    # Override themes for Flatpaks
    sudo flatpak override --filesystem="$HOME/.themes"

    # Select your theme from inside of ./themes
    sudo flatpak override --env=GTK_THEME=Nordic

    display_message "Themes applied to Flatpaks successfully."
}

# Function to check if mitigations=off is present in GRUB configuration
check_mitigations_grub() {
    display_message "Checking if mitigations=off is present in GRUB configuration..."

    # Read the GRUB configuration
    grub_config=$(cat /etc/default/grub)

    # Check if mitigations=off is present
    if echo "$grub_config" | grep -q "mitigations=off"; then
        display_message "Mitigations are currently disabled in GRUB configuration: ==>  ( Success! )"
        sleep 1
    else
        display_message "Warning: Mitigations are not currently disabled in GRUB configuration."
    fi
}

install_apps() {
    display_message "Installing afew personal apps..."

    # Install Kate
    sudo dnf install -y kate git digikam rygel mpg123 rhythmbox python3 python3-pip libffi-devel openssl-devel kate neofetch
    sudo dnf install -y PackageKit timeshift grub-customizer dconf-editor gedit gjs unzip p7zip p7zip-plugins unrar sxiv lsd duf
    sudo dnf install -y ffmpeg-libs earlyoom virt-manager pip libdvdcss gimp gimp-devel 
    sudo dnf swap libavcodec-free libavcodec-freeworld
    sudo dnf install ffmpeg libavcodec-freeworld --best --allowerasing
    
    # Start earlyloom services
    sudo systemctl start earlyoom
    sudo systemctl enable earlyoom

    # Install some fonts
    display_message "Install some fonts"
    sudo dnf install -y fontawesome-fonts powerline-fonts
    sudo mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf
    wget https://github.com/tolgaerok/fonts-tolga/raw/main/WPS-FONTS.zip
    unzip WPS-FONTS.zip -d /usr/share/fonts

    # Reloading Font
    sudo fc-cache -vf

    # Removing zip Files
    rm ./WPS-FONTS.zip
    sudo fc-cache -f -v

    # Install google
    display_message "Installing Google Chrome browser..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
    sudo dnf install -y ./google-chrome-stable_current_x86_64.rpm
    rm -f google-chrome-stable_current_x86_64.rpm

    # Install extra package
    display_message "Extra rpm packages"
    sudo dnf groupupdate -y sound-and-video
    sudo dnf group upgrade -y --with-optional Multimedia
    sudo dnf groupupdate -y sound-and-video --allowerasing --skip-broken
    sudo dnf groupupdate multimedia sound-and-video

    # Download teamviewer
    download_url="https://download.teamviewer.com/download/linux/teamviewer.x86_64.rpm?utm_source=google&utm_medium=cpc&utm_campaign=au%7Cb%7Cpr%7C22%7Cjun%7Ctv-core-download-sn%7Cfree%7Ct0%7C0&utm_content=Download&utm_term=teamviewer+download"
    download_location="/tmp/teamviewer.x86_64.rpm"

    display_message "Downloading TeamViewer..."
    wget -O "$download_location" "$download_url"

    # Install TeamViewer
    display_message "Installing TeamViewer..."
    sudo dnf install "$download_location" -y

    # Cleanup
    display_message "Cleaning up /tmp.."
    rm "$download_location"

    display_message "TeamViewer installation completed."

    # Download Visual Studio Code
    download_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
    download_location="/tmp/vscode.rpm"

    display_message "Downloading Visual Studio Code..."
    wget -O "$download_location" "$download_url"

    # Install Visual Studio Code
    display_message "Installing Visual Studio Code..."
    sudo dnf install "$download_location" -y

    # Cleanup
    display_message "Cleaning up /tmp..."
    rm "$download_location"

    display_message "Install SAMBA and dependencies"

    # Install Samba and its dependencies
    sudo dnf install samba samba-client samba-common cifs-utils samba-usershares -y

    # Enable and start SMB and NMB services
    sudo systemctl enable smb.service nmb.service
    sudo systemctl start smb.service nmb.service

    # Restart SMB and NMB services (optional)
    sudo systemctl restart smb.service nmb.service

    # Configure the firewall
    sudo firewall-cmd --add-service=samba --permanent
    sudo firewall-cmd --add-service=samba
    sudo firewall-cmd --runtime-to-permanent
    sudo firewall-cmd --reload

    # Set SELinux booleans
    sudo setsebool -P samba_enable_home_dirs on
    sudo setsebool -P samba_export_all_rw on
    sudo setsebool -P smbd_anon_write 1

    # Create samba user/group
    read -r -p "Set-up samba user & group's
" -t 2 -n 1 -s

    # Prompt for the desired username for samba
    read -p $'\n'"Enter the USERNAME to add to Samba: " sambausername

    # Prompt for the desired name for samba
    read -p $'\n'"Enter the GROUP name to add username to Samba: " sambagroup

    sudo groupadd $sambagroup
    sudo useradd -m $sambausername
    sudo smbpasswd -a $sambausername
    sudo usermod -aG $sambagroup $sambausername

    read -r -p "
Continuing..." -t 1 -n 1 -s

    # Configure custom samba folder
    read -r -p "Create and configure custom samba folder located at /home/fedora39
" -t 2 -n 1 -s

    sudo mkdir /home/fedora39
    sudo chgrp samba /home/fedora39
    sudo chmod 770 /home/fedora39

    # Create the sambashares group if it doesn't exist
    sudo groupadd -r sambashares

    # Create the usershares directory and set permissions
    sudo mkdir -p /var/lib/samba/usershares
    sudo chown $username:sambashares /var/lib/samba/usershares
    sudo chmod 1770 /var/lib/samba/usershares

    # Restore SELinux context for the usershares directory
    sudo restorecon -R /var/lib/samba/usershares

    # Add the user to the sambashares group
    sudo gpasswd sambashares -a $username

    # Add the user to the sambashares group (alternative method)
    sudo usermod -aG sambashares $username

    # Restart SMB and NMB services (optional)
    sudo systemctl restart smb.service nmb.service

    display_message "Installation completed."

    # Check for errors during installation
    if [ $? -eq 0 ]; then
        display_message "Apps installed successfully."
    else
        display_message "Error: Unable to install Apps."
    fi
}

cleanup_fedora() {
    # Clean package cache
    display_message " Time to clean up system..."
    sudo dnf clean all

    # Remove unnecessary dependencies
    sudo dnf autoremove -y

    # Sort the lists of installed packages and packages to keep
    display_message "Sorting out list of installed packages and packages to keep..."
    comm -23 <(sudo dnf repoquery --installonly --latest-limit=-1 -q | sort) <(sudo dnf list installed | awk '{print $1}' | sort) >/tmp/orphaned-pkgs

    if [ -s /tmp/orphaned-pkgs ]; then
        sudo dnf remove $(cat /tmp/orphaned-pkgs) -y --skip-broken
    else
        display_message "No orphaned packages found."
    fi

    # Clean up temporary files
    display_message "Clean up temporary files ..."
    sudo rm -rf /tmp/orphaned-pkgs

    display_message "Trimming all mount points on SSD"
    sudo fstrim -av

    echo -e "\e[1;32m[✔]\e[0m Restarting kernel tweaks...\n"
    sleep 1
    sudo sysctl -p

    display_message "Cleanup complete, ENJOY!"
}

fix_chrome() {
    display_message "Applying chrome HW accelerations issue for now"
    # Prompt user for reboot or continue
    read -p "Do you want to down grade mesa dlibs now? (y/n): " choice
    case "$choice" in
    y | Y)
        # Apply fix
        display_message "Applied"
        sudo sudo dnf downgrade mesa-libGL
        sudo rm -rf ./config/google-chrome
        sudo rm -rf ./cache/google-chrome
        sudo chmod -R 770 ~/.cache/google-chrome
        sudo chmod -R 770 ~/.config/google-chrome

        sleep 2
        display_message "Bug @ https://bugzilla.redhat.com/show_bug.cgi?id=2193335"
        ;;
    n | N)
        display_message "Fix skipped. Continuing with the script."
        ;;
    *)
        display_message "Invalid choice. Continuing with the script."
        ;;
    esac

    echo "If problems persist, copy and pate the following into chrome address bar and disable HW acceleration"
    echo ""
    echo "chrome://settings/?search=hardware+acceleration"
    sleep 3
    sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tolgaerok/tolga-scripts/main/Fedora39/execute-python-script.sh)"
}

display_XDG_session() {
    session=$XDG_SESSION_TYPE

    display_message "Current XDG session is [ $session ]"
    echo "Current XDG session is [ $session ]"

}

fix_grub() {
    # Check if GRUB_TIMEOUT_STYLE is present
    if ! grep -q '^GRUB_TIMEOUT_STYLE=menu' /etc/default/grub; then
        # Add GRUB_TIMEOUT_STYLE=menu if not present
        echo 'GRUB_TIMEOUT_STYLE=menu' | sudo tee -a /etc/default/grub >/dev/null
    fi

    # Check if UEFI is enabled
    uefi_enabled=$(test -d /sys/firmware/efi && echo "UEFI" || echo "BIOS/Legacy")

    # Display information about GRUB configuration
    display_message "Current GRUB configuration:"
    echo "  - GRUB_TIMEOUT_STYLE: $(grep '^GRUB_TIMEOUT_STYLE' /etc/default/grub | cut -d '=' -f2)"
    echo "  - System firmware: $uefi_enabled"

    # Prompt user to proceed
    read -p "Do you want to proceed with updating GRUB? (yes/no): " choice
    case "$choice" in
    [Yy] | [Yy][Ee][Ss]) ;;
    *)
        echo "GRUB update aborted."
        return
        ;;
    esac

    # Update GRUB configuration
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

    echo "GRUB updated successfully."
}

# Function to display the main menu
display_main_menu() {
    clear
    clear
    echo -e "\n                  Tolga's online Fedora updater\n"
    echo -e "\e[34m|--------------------------|\e[33m Main Menu \e[34m |-------------------------------------|\e[0m"
    echo -e "\e[33m 1.\e[0m \e[32m Configure faster updates in DNF\e[0m"
    echo -e "\e[33m 2.\e[0m \e[32m Install RPM Fusion repositories\e[0m"
    echo -e "\e[33m 3.\e[0m \e[32m Update the system                 ( Create meta cache etc )\e[0m"
    echo -e "\e[33m 4.\e[0m \e[32m Install firmware updates          ( Not compatible with all systems )\e[0m"
    echo -e "\e[33m 5.\e[0m \e[32m Install Nvidia / AMD GPU drivers  ( Auto scan and install )\e[0m"
    echo -e "\e[33m 6.\e[0m \e[32m Optimize battery life\e[0m"
    echo -e "\e[33m 7.\e[0m \e[32m Install multimedia codecs\e[0m"
    echo -e "\e[33m 8.\e[0m \e[32m Install H/W Video Acceleration for AMD or Intel\e[0m"
    echo -e "\e[33m 9.\e[0m \e[32m Update Flatpak\e[0m"
    echo -e "\e[33m 10.\e[0m \e[32mSet UTC Time\e[0m"
    echo -e "\e[33m 11.\e[0m \e[32mDisable mitigations\e[0m"
    echo -e "\e[33m 12.\e[0m \e[32mEnable Modern Standby\e[0m"
    echo -e "\e[33m 13.\e[0m \e[32mEnable nvidia-modeset\e[0m"
    echo -e "\e[33m 14.\e[0m \e[32mDisable NetworkManager-wait-online.service\e[0m"
    echo -e "\e[33m 15.\e[0m \e[32mDisable Gnome Software from Startup Apps\e[0m"
    echo -e "\e[33m 16.\e[0m \e[32mChange hostname                   ( Change current localname/pc name )\e[0m"
    echo -e "\e[33m 17.\e[0m \e[32mCheck mitigations=off in GRUB\e[0m"
    echo -e "\e[33m 18.\e[0m \e[32mInstall additional apps\e[0m"
    echo -e "\e[33m 19.\e[0m \e[32mCleanup Fedora\e[0m"
    echo -e "\e[33m 20.\e[0m \e[32mFix Chrome HW accelerations issue ( No guarantee )\e[0m"
    echo -e "\e[33m 21.\e[0m \e[32mDisplay XDG session\e[0m"
    echo -e "\e[33m 22.\e[0m \e[32mFix grub or rebuild grub          ( Checks and enables menu output to grub menu )\e[0m"
    echo -e "\e[33m 23.\e[0m \e[32mInstall new DNF5                  ( Testing for fedora 40/41 )\e[0m"
    echo -e "\e[34m|-------------------------------------------------------------------------------|\e[0m"
    echo -e "\e[31m   (0) \e[0m \e[32mExit\e[0m"
    echo -e "\e[34m|-------------------------------------------------------------------------------|\e[0m"
    echo ""

}

# Function to handle user input
handle_user_input() {

    echo -e "${YELLOW}┌──($USER㉿$HOST)-[$(pwd)]${NC}"

    choice=""
    echo -n -e "${YELLOW}└─\$>>${NC} "
    read choice

    echo ""
   # clear
   # read -p "Enter your choice (0-21): " choice
    case "$choice" in
    1) configure_dnf ;;
    2) install_rpmfusion ;;
    3) update_system ;;
    4) install_firmware ;;
    5) install_gpu_drivers ;;
    6) optimize_battery ;;
    7) install_multimedia_codecs ;;
    8) install_hw_video_acceleration_amd_or_intel ;;
    9) update_flatpak ;;
    10) set_utc_time ;;
    11) disable_mitigations ;;
    12) enable_modern_standby ;;
    13) enable_nvidia_modeset ;;
    14) disable_network_manager_wait_online ;;
    15) disable_gnome_software_startup ;;
    16) change_hotname ;;
    17) check_mitigations_grub ;;
    18) install_apps ;;
    19) cleanup_fedora ;;
    20) fix_chrome ;;
    21) display_XDG_session ;;
    22) fix_grub ;;
    23) dnf5 ;;

    0) exit ;;
    *)
        echo -e "Invalid choice. Please enter a number from 0 to 21."
        sleep 2
        ;;
    esac
}

# Main loop for the menu
while true; do
    display_main_menu
    handle_user_input
done
