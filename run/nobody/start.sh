#!/usr/bin/dumb-init /bin/bash

# CONFIG_PLACEHOLDER

# create env var for display (note display number must match for tigervnc)
export DISPLAY=:0

# vnc start command
vnc_start="rm -rf /tmp/.X*; Xvnc :0 -depth 24"

# if a password is specified then generate password file in /home/nobody/.vnc/passwd
# else append insecure flag to command line
if [[ -n "${VNC_PASSWORD}" ]]; then
	password_length="${#VNC_PASSWORD}"
	if [[ "${password_length}" -gt 5 ]]; then
		echo "[info] Password length OK, proceeding to set password..."
		echo -e "${VNC_PASSWORD}\n${VNC_PASSWORD}\nn" | vncpasswd 1>&- 2>&-
		vnc_start="${vnc_start} -PasswordFile=${HOME}/.vnc/passwd"
	else
		echo "[warn] Password specified is less than 6 characters and thus will be ignored."
		vnc_start="${vnc_start} -SecurityTypes=None"
	fi
else
	vnc_start="${vnc_start} -SecurityTypes=None"
fi

# if defined then set title for the web ui tab
if [[ -n "${WEBPAGE_TITLE}" ]]; then
	vnc_start="${vnc_start} -Desktop='${WEBPAGE_TITLE}'"
fi

# Get the container's IP address, excluding the loopback interface
IP_ADDRESS=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Check if an IP address was found
if [ -n "$IP_ADDRESS" ]; then
    # Export the IP address as an environment variable
    export CONTAINER_IP="$IP_ADDRESS"
    echo "CONTAINER_IP environment variable set to: $CONTAINER_IP"
else
    echo "No IP address found for the container."
    exit 1
fi

# start tigervnc (vnc server) - note the port that it runs on is 5900 + display number (i.e. 5900 + 0 in the case below).
eval "${vnc_start}" &

# starts novnc (web vnc client) - note also starts websockify to connect novnc to tigervnc server
/usr/sbin/websockify --web /usr/share/webapps/novnc/ 6080 localhost:5900 &

# Launch Xfce in the background.

/usr/local/bin/autostart_fs25.sh &

dbus-launch startxfce4

# STARTCMD_PLACEHOLDER

# run cat in foreground, this prevents start.sh script from exiting and ending all background processes
cat
