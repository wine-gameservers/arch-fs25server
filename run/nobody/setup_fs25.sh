#!/bin/bash

# Path to the Farming Simulator executable
FS25_EXEC="$HOME/.fs25server/drive_c/Program Files (x86)/Farming Simulator 2025/FarmingSimulator2025.exe"
# Path to the installer directory
INSTALLER_PATH="/opt/fs25/installer/FarmingSimulator2025.exe"

# Required free space in GB
REQUIRED_SPACE=45

. /usr/local/bin/wine_init.sh

# Check dlc's

if [ -f /opt/fs25/dlc/FarmingSimulator25_extraContentNewHollandCR11_*.exe ]; then
    echo -e "${GREEN}INFO: New Holland CR11 Gold Edition SETUP FOUND!${NOCOLOR}"
else
	echo -e "${YELLOW}WARNING: New Holland CR11 Gold Edition Setup not found, do you own it and does it exist in the dlc mount path?${NOCOLOR}"
	echo -e "${YELLOW}WARNING: If you do not own it ignore this!${NOCOLOR}"
fi

if [ -f /opt/fs25/dlc/FarmingSimulator25_macDonPack_*.exe ]; then
    echo -e "${GREEN}INFO: MacDon SETUP FOUND!${NOCOLOR}"
else
        echo -e "${YELLOW}WARNING: MacDon Setup not found, do you own it and does it exist in the dlc mount path?${NOCOLOR}"
        echo -e "${YELLOW}WARNING: If you do not own it ignore this!${NOCOLOR}"
fi

if [ -f /opt/fs25/dlc/FarmingSimulator25_nexatPack_*.exe ]; then
    echo -e "${GREEN}INFO: NEXAT Pack FOUND!${NOCOLOR}"
else
        echo -e "${YELLOW}WARNING: NEXAT Pack not found, do you own it and does it exist in the dlc mount path?${NOCOLOR}"
        echo -e "${YELLOW}WARNING: If you do not own it ignore this!${NOCOLOR}"
fi

if [ -f /opt/fs25/dlc/FarmingSimulator25_plainsAndPrairiesPack_*.exe ]; then
    echo -e "${GREEN}INFO: Plains & Prairies Pack FOUND!${NOCOLOR}"
else
        echo -e "${YELLOW}WARNING: Plains & Prairies Pack not found, do you own it and does it exist in the dlc mount path?${NOCOLOR}"
        echo -e "${YELLOW}WARNING: If you do not own it ignore this!${NOCOLOR}"
fi

# it's important to check if the config directory exists on the host mount path. If it doesn't exist, create it.

if [ -d /opt/fs25/config/FarmingSimulator2025 ]
then
    echo -e "${GREEN}INFO: The host config directory exists, no need to create it!${NOCOLOR}"
else
mkdir -p /opt/fs25/config/FarmingSimulator2025

fi

# it's important to check if the game directory exists on the host mount path. If it doesn't exist, create it.

if [ -d /opt/fs25/game/Farming\ Simulator\ 2025 ]
then
    echo -e "${GREEN}INFO: The host game directory exists, no need to create it!${NOCOLOR}"
else
mkdir -p /opt/fs25/game/Farming\ Simulator\ 2025

fi

. /usr/local/bin/wine_symlinks.sh

# Check if the executable exists
if [ ! -f "$FS25_EXEC" ]; then
    echo -e "${GREEN}INFO: FarmingSimulator2025.exe does not exist. Checking available space...${NOCOLOR}"

    # Get available free space in /opt/fs25 (in GB)
    AVAILABLE_SPACE=$(df --output=avail /opt/fs25 | tail -1)
    AVAILABLE_SPACE=$((AVAILABLE_SPACE / 1024 / 1024)) # Convert KB to GB

    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        echo -e "${RED}ERROR:Not enough free space in /opt/fs25. Required: $REQUIRED_SPACE GB, Available: $AVAILABLE_SPACE GB${NOCOLOR}"
        exit 1
    fi

    echo -e "${GREEN}INFO: Sufficient space available. Running the installer...${NOCOLOR}"
    wine "$INSTALLER_PATH" "/SILENT" "/NOCANCEL" "/NOICONS"
else
    echo -e "${GREEN}INFO: FarmingSimulator2025.exe already exists. No action needed.${NOCOLOR}"
fi

# Cleanup Desktop

# Find files starting with "Farming" on /home/nobody/Desktop
icons=$(find /home/nobody/Desktop -type f -name 'Farming*')

# Check if any files are found
if [ -n "$icons" ]; then
    # Remove all icons starting with "Farming"
    find /home/nobody/Desktop -type f -name 'Farming*' -exec rm -f {} \;
    echo -e "${GREEN}INFO: Files starting with 'Farming' have been removed...${NOCOLOR}"
else
    echo -e "${GREEN}INFO: No desktop icons to cleanup!${NOCOLOR}"
fi

# Do we have a license file installed?

count=`ls -1 ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/*.dat 2>/dev/null | wc -l`
if [ $count != 0 ]
then
    echo -e "${GREEN}INFO: Generating the game license files as needed!${NOCOLOR}"
else
    wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe
fi

count=`ls -1 ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/*.dat 2>/dev/null | wc -l`
if [ $count != 0 ]
then
    echo -e "${GREEN}INFO: The license files are in place!${NOCOLOR}"
else
    echo -e "${RED}ERROR: No license files detected, they are generated after you enter the cd-key during setup... most likely the setup is failing to start!${NOCOLOR}" && exit
fi

. /usr/local/bin/copy_server_config.sh


# Install DLC

if [ -f ~/.fs25server/drive_c/users/nobody/Documents/My\ Games/FarmingSimulator2025/pdlc/extraContentNewHollandCR11.dlc ]
then
    echo -e "${GREEN}INFO: New Holland CR11 Gold Edition already installed!${NOCOLOR}"
else
    if [ -f /opt/fs25/dlc/FarmingSimulator25_extraContentNewHollandCR11_*.exe ]; then
        echo -e "${GREEN}INFO: Installing New Holland CR11 Gold Edition!${NOCOLOR}"
        for i in /opt/fs25/dlc/FarmingSimulator25_extraContentNewHollandCR11*.exe; do wine "$i"; done
        echo -e "${GREEN}INFO: New Holland CR11 Gold Edition is now installed!${NOCOLOR}"
    fi
fi

if [ -f ~/.fs25server/drive_c/users/nobody/Documents/My\ Games/FarmingSimulator2025/pdlc/macDonPack.dlc ]
then
    echo -e "${GREEN}INFO: MacDon Pack is already installed!${NOCOLOR}"
else
    if [ -f /opt/fs25/dlc/FarmingSimulator25_macDonPack_*.exe ]; then
        echo -e "${GREEN}INFO: Installing MacDon Pack..!${NOCOLOR}"
        for i in /opt/fs25/dlc/FarmingSimulator25_macDonPack*.exe; do wine "$i"; done
        echo -e "${GREEN}INFO: MacDon Pack is now installed!${NOCOLOR}"
    fi
fi

if [ -f ~/.fs25server/drive_c/users/nobody/Documents/My\ Games/FarmingSimulator2025/pdlc/nexatPack.dlc ]
then
    echo -e "${GREEN}INFO: NEXAT Pack is already installed!${NOCOLOR}"
else
    if [ -f /opt/fs25/dlc/FarmingSimulator25_nexatPack_*.exe ]; then
        echo -e "${GREEN}INFO: Installing NEXAT Pack..!${NOCOLOR}"
        for i in /opt/fs25/dlc/FarmingSimulator25_nexatPack*.exe; do wine "$i"; done
        echo -e "${GREEN}INFO: NEXAT Pack is now installed!${NOCOLOR}"
    fi
fi

if [ -f ~/.fs25server/drive_c/users/nobody/Documents/My\ Games/FarmingSimulator2025/pdlc/plainsAndPrairiesPack.dlc ]
then
    echo -e "${GREEN}INFO: Plains & Prairies Pack is already installed!${NOCOLOR}"
else
    if [ -f /opt/fs25/dlc/FarmingSimulator25_plainsAndPrairiesPack_*.exe ]; then
        echo -e "${GREEN}INFO: Installing Plains & Prairies Pack..!${NOCOLOR}"
        for i in /opt/fs25/dlc/FarmingSimulator25_plainsAndPrairiesPack*.exe; do wine "$i"; done
        echo -e "${GREEN}INFO: Plains & Prairies Pack is now installed!${NOCOLOR}"
    fi
fi

# Check for updates

echo -e "${YELLOW}INFO: Checking for updates, if you get warning about gpu drivers make sure to click no!${NOCOLOR}"
wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe

# Check config if not exist exit

if [ -f ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/dedicatedServerConfig.xml ]
then
    echo -e "${GREEN}INFO: We can run the server now by clicking on 'Start Server' on the desktop!${NOCOLOR}"
else
    echo -e "${RED}ERROR: We are missing files?${NOCOLOR}" && exit
fi

. /usr/local/bin/cleanup_logs.sh

echo -e "${YELLOW}INFO: Checking for updates, if you get warning about gpu drivers make sure to click no!${NOCOLOR}"
wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe

echo -e "${YELLOW}INFO: All done, closing this window in 20 seconds...${NOCOLOR}"

exec sleep 20
