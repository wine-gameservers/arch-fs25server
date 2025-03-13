#!/bin/bash

# Symlink the host game path inside the wine prefix to preserve the installation on image deletion or update.

if [ -d /opt/fs25/game/Farming\ Simulator\ 2025 ]
then
    ln -s /opt/fs25/game/Farming\ Simulator\ 2025 ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025
else
echo -e "${RED}Error: There is a problem... the host game directory does not exist, unable to create the symlink, the installation has failed!${NOCOLOR}"
fi

# Symlink the host config path inside the wine prefix to preserver the config files on image deletion or update.

if [ -d ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025 ]
then
    echo -e "${GREEN}INFO: The symlink is already in place, no need to create one!${NOCOLOR}"
else
mkdir -p ~/.fs25server/drive_c/users/$USER/Documents/My\ Games && ln -s /opt/fs25/config/FarmingSimulator2025 ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025
fi

if [ -d ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs ]
then
    echo -e "${GREEN}INFO: The log directories are in place!${NOCOLOR}"
else
    mkdir -p ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/logs
fi
