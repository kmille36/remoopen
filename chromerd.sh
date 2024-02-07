#!/bin/bash

username="user"
password="root"

echo "Creating User and Setting it up"

# Creation of user
useradd -m "$username"

# Add user to sudo group
adduser "$username" sudo
    
# Set password of user to 'root'
echo "$username:$password" | sudo chpasswd

# Change default shell from sh to bash
sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

echo "User created and configured having username '$username' and password '$password'"


# Prompt user for CRP
read -p "Enter the authentication code from http://remotedesktop.google.com/headless: " CRP

# Check if CRP is provided
if [ -z "$CRP" ]; then
    echo "Authentication code (CRP) cannot be empty"
    exit 1
fi

# Set other variables
Pin="123456"
Autostart=true
user="user"

# Update packages
apt update

#Audio support
sudo apt install pulseaudio -y

# Function to install Chrome Remote Desktop
install_CRD() {
    echo "Installing Chrome Remote Desktop"
    wget -qO chrome-remote-desktop_current_amd64.deb https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    apt install --assume-yes --fix-broken
}

# Function to install Desktop Environment
install_desktop_environment() {
    echo "Installing Desktop Environment"
    export DEBIAN_FRONTEND=noninteractive
    apt install --assume-yes xfce4 desktop-base xfce4-terminal
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
    apt remove --assume-yes gnome-terminal
    apt install --assume-yes xscreensaver
    systemctl disable lightdm.service
}

# Function to install Google Chrome
install_google_chrome() {
    echo "Installing Google Chrome"
    wget -qO google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg --install google-chrome-stable_current_amd64.deb
    apt install --assume-yes --fix-broken
}



# Function to finalize setup
finish_setup() {
    echo "Finalizing setup"
    if [ "$Autostart" = true ]; then
        mkdir -p /home/$user/.config/autostart
        link="https://colab.research.google.com/github/PradyumnaKrishna/Colab-Hacks/blob/master/Colab%20RDP/Colab%20RDP.ipynb"
        colab_autostart="[Desktop Entry]\nType=Application\nName=Colab\nExec=sh -c \"sensible-browser $link\"\nIcon=\nComment=Open a predefined notebook at session signin.\nX-GNOME-Autostart-enabled=true"
        echo -e "$colab_autostart" > /home/$user/.config/autostart/colab.desktop
        RUN echo "/usr/bin/pulseaudio --start" >> /home/$user/.config/autostart/colab.desktop
        chmod +x /home/$user/.config/autostart/colab.desktop
        chown $user:$user /home/$user/.config
    fi
    adduser $user chrome-remote-desktop
    command="$CRP --pin=$Pin"
    su - $user -c "$command"
    service chrome-remote-desktop start
    echo "Setup completed successfully"
}

# Check if username is provided
if [ -z "$user" ]; then
    echo "Please provide a username"
    exit 1
fi



# Call functions
install_CRD
install_desktop_environment
install_google_chrome
finish_setup
