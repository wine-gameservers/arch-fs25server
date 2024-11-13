#!/bin/bash

export WINEDEBUG=-all
export WINEPREFIX=~/.fs25server

# Start the server

if [ -f ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/dedicatedServer.exe ]
then
    wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/dedicatedServer.exe
else
    echo "Game not installed?" && exit
fi

exit 0
