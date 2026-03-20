#!/bin/bash

export WINEDEBUG=-all
export WINEPREFIX=~/.fs25server

# Start the server

if [ -f ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/dedicatedServer.exe ]
then
    bash /usr/local/bin/set-web-darkmode.sh
    bash /usr/local/bin/patch_web_ip.sh
    wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/dedicatedServer.exe & sleep 1 && firefox "http://"$CONTAINER_IP":7999/index.html?lang=en&username="$WEB_USERNAME"&password="$WEB_PASSWORD"&login=Login"
else
    echo "Game not installed?" && exit
fi

exit 0
