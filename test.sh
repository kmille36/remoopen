#!/bin/bash
# remote_desktop.sh
# This script sets up a remote desktop environment with XFCE4, TurboVNC, and noVNC.
# Users can connect via a web browser to control the desktop.
#
# Requirements:
#   - A Debian/Ubuntu-based Linux system
#   - apt-get package manager
#   - sudo privileges to bind to port 80 (or change port if desired)
#
# The script performs the following steps:
#   1. Installs XFCE4, TurboVNC, and noVNC (with websockify).
#   2. Sets a VNC password (change "yourpassword" as needed).
#   3. Configures the VNC startup to launch XFCE4.
#   4. Starts the TurboVNC server on display :1.
#   5. Launches noVNC (using websockify) on port 80 to forward to the VNC server.
#
# After running, open a browser at http://<your_ip>/vnc.html

set -e

echo "Updating package list..."
sudo apt-get update

echo "Installing XFCE4 and required packages..."
sudo apt-get install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils

echo "Installing TurboVNC..."
sudo apt-get install -y turbovnc

echo "Installing noVNC and websockify..."
sudo apt-get install -y novnc websockify

# Set up VNC password non-interactively (change "yourpassword" as needed)
mkdir -p ~/.vnc
echo "yourpassword" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Configure VNC startup to launch XFCE4.
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup

# Kill any existing VNC server on display :1 (ignore error if none exists)
vncserver -kill :1 || true

echo "Starting TurboVNC server on display :1 with 1920x1080 resolution..."
vncserver :1 -geometry 1920x1080 -depth 24

# noVNC will connect to the VNC server's port.
# By default TurboVNC uses port 5901 for display :1.
# Launch noVNC using websockify to forward port 80 to localhost:5901.
echo "Starting noVNC server on port 80..."
# Note: Binding to port 80 may require sudo. If you prefer a higher port (e.g. 8080), change it accordingly.
sudo websockify --web=/usr/share/novnc 80 localhost:5901 &

NOVNC_PID=$!
echo "noVNC server started (PID $NOVNC_PID)."
echo "Remote desktop available! Open your browser and navigate to:"
echo "    http://<your_ip>/vnc.html"
echo "Login with the VNC password you set (in this script, 'yourpassword')."
echo "Press Ctrl+C to stop."

# Keep the script running.
tail -f /dev/null
