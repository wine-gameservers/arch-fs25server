#!/bin/bash

# Path to the game installer directory (where the game installation files are stored)
INSTALL_DIR="/opt/fs25/installer"

# Path to the config  directory (where the game config files are stored)
CONFIG_DIR="/opt/fs25/config"

# Path to the DLC installer directory (where downloaded DLCs are stored)
DLC_DIR="/opt/fs25/dlc"

# Path to the DLC install directory
PDLC_DIR="${CONFIG_DIR}/FarmingSimulator2025/pdlc"

# DLC filename prefix (used to identify official DLC packages)
DLC_PREFIX="FarmingSimulator25_"

# Path to the Farming Simulator executable
FS25_EXEC="$HOME/.fs25server/drive_c/Program Files (x86)/Farming Simulator 2025/FarmingSimulator2025.exe"


# Check which installer file exists
if [ -f "$INSTALL_DIR/FarmingSimulator2025.exe" ]; then
    INSTALLER_PATH="$INSTALL_DIR/FarmingSimulator2025.exe"
elif [ -f "$INSTALL_DIR/Setup.exe" ]; then
    INSTALLER_PATH="$INSTALL_DIR/Setup.exe"
else
    echo "Error: No installer found in $INSTALL_DIR"
    exit 1
fi


# Check DLCs (list what we found and what is installed)

echo -e "${GREEN}INFO: Scanning ${DLC_DIR} for DLC installers...${NOCOLOR}"

# Enable nullglob to handle no matches gracefully
shopt -s nullglob

declare -a supported_names=()
declare -A seen=()
declare -a unsupported=()

# Collect installers
for path in "$DLC_DIR"/${DLC_PREFIX}*; do
  [ -e "$path" ] || break
  base="$(basename "$path")"
  ext="${base##*.}"

  case "$ext" in
    exe|EXE)
      # Example: FarmingSimulator25_highlandsFishingPack_1_1_0_0_ESD.exe
      raw="${base#${DLC_PREFIX}}"   # highlandsFishingPack_1_1_0_0_ESD.exe
      name="${raw%%_*}"             # highlandsFishingPack
      if [[ -z "${seen[$name]:-}" ]]; then
        supported_names+=("$name")
        seen["$name"]=1
      fi
      ;;
      # zip/bin installers not supported, check and warn user
    zip|ZIP|bin|BIN)
      unsupported+=("$base")
      ;;
    *)
      # ignore other file types silently
      :
      ;;
  esac
done

if ((${#supported_names[@]})); then
  echo -e "${GREEN}INFO: DLCs found:${NOCOLOR} ${supported_names[*]}"
else
  echo -e "${YELLOW}Info: DLCs installers (.exe) found in ${DLC_DIR}.${NOCOLOR}"
fi

if ((${#unsupported[@]})); then
  echo -e "${YELLOW}WARNING: The following files were found but are NOT supported (bin/zip), please use .exe:${NOCOLOR}"
  for u in "${unsupported[@]}"; do
    echo " - $u"
  done
fi

# Show installed status for each supported DLC
if ((${#supported_names[@]})); then
  echo -e "${GREEN}INFO: Checking installed DLC status...${NOCOLOR}"
  for name in "${supported_names[@]}"; do
    if [ -f "${PDLC_DIR}/${name}.dlc" ]; then
      echo -e "${GREEN}INFO: ${name} is already installed.${NOCOLOR}"
    else
      echo -e "${YELLOW}INFO: ${name} is not installed yet.${NOCOLOR}"
    fi
  done
fi

# Required free space in GB
REQUIRED_SPACE=50

. /usr/local/bin/wine_init.sh


# Check DLCs (list what we found and what is installed)

echo -e "${GREEN}INFO: Scanning ${DLC_DIR} for DLC installers...${NOCOLOR}"

# Enable nullglob to handle no matches gracefully
shopt -s nullglob

declare -a supported_names=()
declare -A seen=()
declare -a unsupported=()

# Collect installers
for path in "$DLC_DIR"/${DLC_PREFIX}*; do
  [ -e "$path" ] || break
  base="$(basename "$path")"
  ext="${base##*.}"

  case "$ext" in
    exe|EXE)
      # Example: FarmingSimulator25_highlandsFishingPack_1_1_0_0_ESD.exe
      raw="${base#${DLC_PREFIX}}"   # highlandsFishingPack_1_1_0_0_ESD.exe
      name="${raw%%_*}"             # highlandsFishingPack
      if [[ -z "${seen[$name]:-}" ]]; then
        supported_names+=("$name")
        seen["$name"]=1
      fi
      ;;
      # zip/bin installers not supported, check and warn user
    zip|ZIP|bin|BIN)
      unsupported+=("$base")
      ;;
    *)
      # ignore other file types silently
      :
      ;;
  esac
done

if ((${#supported_names[@]})); then
  echo -e "${GREEN}INFO: DLCs found:${NOCOLOR} ${supported_names[*]}"
else
  echo -e "${YELLOW}Info: DLCs installers (.exe) found in ${DLC_DIR}.${NOCOLOR}"
fi

if ((${#unsupported[@]})); then
  echo -e "${YELLOW}WARNING: The following files were found but are NOT supported (bin/zip), please use .exe:${NOCOLOR}"
  for u in "${unsupported[@]}"; do
    echo " - $u"
  done
fi

# Show installed status for each supported DLC
if ((${#supported_names[@]})); then
  echo -e "${GREEN}INFO: Checking installed DLC status...${NOCOLOR}"
  for name in "${supported_names[@]}"; do
    if [ -f "${PDLC_DIR}/${name}.dlc" ]; then
      echo -e "${GREEN}INFO: ${name} is already installed.${NOCOLOR}"
    else
      echo -e "${YELLOW}INFO: ${name} is not installed yet.${NOCOLOR}"
    fi
  done
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

count=$(ls -1 ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/*.dat 2>/dev/null | wc -l)
if [ $count != 0 ]; then
        echo -e "${GREEN}INFO: Generating the game license files as needed!${NOCOLOR}"
else
        wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe
fi

count=$(ls -1 ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/*.dat 2>/dev/null | wc -l)
if [ $count != 0 ]; then
        echo -e "${GREEN}INFO: The license files are in place!${NOCOLOR}"
else
        echo -e "${RED}ERROR: No license files detected, they are generated after you enter the cd-key during setup... most likely the setup is failing to start!${NOCOLOR}" && exit
fi

. /usr/local/bin/copy_server_config.sh

# Install DLC (only those not already installed)

echo -e "${GREEN}INFO: Installing missing DLCs (if any)...${NOCOLOR}"

if ((${#supported_names[@]})); then
  for dlc_name in "${supported_names[@]}"; do
    if [ -f "${PDLC_DIR}/${dlc_name}.dlc" ]; then
      # Already installed; skip
      continue
    fi

    # Install missing DLC
    echo -e "${GREEN}INFO: Installing ${dlc_name} (ESD)...${NOCOLOR}"
    any_ran=false
    for i in "$DLC_DIR"/${DLC_PREFIX}${dlc_name}_*.exe; do
      [ -e "$i" ] || break
      any_ran=true
      echo -e "${GREEN}INFO: Running installer ${i}${NOCOLOR}"
      wine "$i"
    done

	# Check if any installer was run
    if ! $any_ran; then
      echo -e "${YELLOW}WARNING: No matching installer found for ${dlc_name} (expected ${DLC_PREFIX}${dlc_name}_*.exe).${NOCOLOR}"
      continue
    fi

    # Verify installation
    if [ -f "${PDLC_DIR}/${dlc_name}.dlc" ]; then
      echo -e "${GREEN}INFO: ${dlc_name} is now installed!${NOCOLOR}"
    else
      echo -e "${YELLOW}WARNING: ${dlc_name} installer ran, but didnt install the DLC. ${NOCOLOR}" #but ${dlc_name}.dlc not found yet.
    fi
  done
else
  echo -e "${YELLOW}WARNING: No DLC installers to process.${NOCOLOR}"
fi


# Check for updates

echo -e "${YELLOW}INFO: Checking for updates, if you get warning about gpu drivers make sure to click no!${NOCOLOR}"
wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe

# Replace VERSION File after update / Create VERSION File after first Install -> fix Version to old error for Future DLCs
cp /opt/fs25/game/Farming\ Simulator\ 2025/VERSION /opt/fs25/config/FarmingSimulator2025/

# Check config if not exist exit

if [ -f ~/.fs25server/drive_c/users/$USER/Documents/My\ Games/FarmingSimulator2025/dedicated_server/dedicatedServerConfig.xml ]; then
        echo -e "${GREEN}INFO: We can run the server now by clicking on 'Start Server' on the desktop!${NOCOLOR}"
else
        echo -e "${RED}ERROR: We are missing files?${NOCOLOR}" && exit
fi

. /usr/local/bin/cleanup_logs.sh

# Closing window

echo -e "${YELLOW}INFO: All done, closing this window in 20 seconds...${NOCOLOR}"

exec sleep 20
