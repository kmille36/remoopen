#!/bin/bash
set -e

echo "Updating package list and installing dependencies..."
# Update and install packages (xfce4, novnc, websockify, turbovnc, xvfb, git, and python3-pip)
sudo apt-get update
sudo apt-get install -y xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils novnc websockify turbovnc xvfb git python3-pip

echo "Installing pyngrok for tunnel creation..."
sudo pip3 install pyngrok

echo "Starting Xvfb virtual display on :1 (1920x1080, 24-bit)..."
# Start Xvfb in the background (this provides a virtual display for XFCE4)
Xvfb :1 -screen 0 1920x1080x24 &
export DISPLAY=:1

echo "Launching XFCE4 desktop..."
# Start a lightweight XFCE4 session
# (It might be necessary to tweak this if the session does not auto-start)
startxfce4 &

echo "Cloning selkies-gstreamer repository..."
# Clone the remote desktop streaming project (selkies-gstreamer)
git clone https://github.com/selkies-project/selkies-gstreamer.git
cd selkies-gstreamer

echo "Installing Python dependencies for selkies-gstreamer..."
# Install required Python packages (adjust requirements as needed)
pip3 install -r requirements.txt || true

echo "Starting selkies-gstreamer web server..."
# Launch the web server (this should start the remote streaming service)
# The repository provides a file like web.py that acts as an entrypoint.
# You may need to adjust the command based on the repo’s instructions.
nohup python3 web.py &

# Save the PID for later use if needed
SELKIES_PID=$!
echo "Selkies-GStreamer server started (PID ${SELKIES_PID})."

echo "Setting up ngrok tunnel for port 80..."
# Create an ngrok tunnel to expose port 80 (which selkies-gstreamer uses for its web interface)
python3 - <<EOF
from pyngrok import ngrok
public_url = ngrok.connect(80)
print("Public URL:", public_url)
EOF

echo "Setup complete!"
echo "Open your browser and navigate to the public URL shown above to access the remote desktop."
echo "Press Ctrl+C to stop."
# Keep the script running so that background processes are not terminated
tail -f /dev/null
