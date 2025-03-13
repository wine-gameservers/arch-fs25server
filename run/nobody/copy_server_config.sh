#!/bin/bash

# Copy webserver config...

if [ -d ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/ ]
then
  cp "/home/nobody/.build/fs25/default_dedicatedServer.xml" ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/dedicatedServer.xml
else
  echo -e "${RED}ERROR: Game is not installed?${NOCOLOR}" && exit
fi

# Copy server config

if [ -d ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/ ]
then
  cp "/home/nobody/.build/fs25/default_dedicatedServerConfig.xml" ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/dedicatedServerConfig.xml
else
  echo -e "${RED}ERROR: Game didn't start for first time, no directories?${NOCOLOR}" && exit
fi
