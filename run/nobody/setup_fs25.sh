#!/bin/bash
# Debug info/warning/error color
NOCOLOR='\033[0;0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

# Path to the game installer directory (where the game installation files are stored)
INSTALL_DIR="/opt/fs25/installer"


# Path to the config  directory (where the game config files are stored)
CONFIG_DIR="/opt/fs25/config/FarmingSimulator2025"

# Path to the DLC installer directory (where downloaded DLCs are stored)
DLC_DIR="/opt/fs25/dlc"

# Path to the DLC install directory
PDLC_DIR="${CONFIG_DIR}/pdlc"

# DLC filename prefix (used to identify official DLC packages)
DLC_PREFIX="FarmingSimulator25_"

# Path to the Farming Simulator executable
FS25_EXEC="$HOME/.fs25server/drive_c/Program Files (x86)/Farming Simulator 2025/FarmingSimulator2025.exe"

# set game installed false, will be set to true if we detect the game is already installed
GAME_INSTALLED=false

# Enable nullglob to handle no matches gracefully
shopt -s nullglob


# Check if the game is already installed
if [ -f "$FS25_EXEC" ]; then
  echo -e "${GREEN}INFO: Game already installed; skipping installer detection.${NOCOLOR}"
  GAME_INSTALLED=true
fi

# Check which installer file exists and extract if needed
if [ "$GAME_INSTALLED" = false ]; then
  if [ -f "$INSTALL_DIR/FarmingSimulator2025.exe" ]; then
      INSTALLER_PATH="$INSTALL_DIR/FarmingSimulator2025.exe"

  elif [ -f "$INSTALL_DIR/Setup.exe" ]; then
      INSTALLER_PATH="$INSTALL_DIR/Setup.exe"

  else
      echo "${YELLOW}Installer not found, trying to extract IMG…"

      # Collect all matching IMG files
      imgs=( "$INSTALL_DIR"/FarmingSimulator25_*_ESD.img )

      # No matches
      if ((${#imgs[@]} == 0)); then
          echo -e "${RED}Error: No FarmingSimulator25_*_ESD.img found in $INSTALL_DIR${NOCOLOR}"
          exit 1
      fi

      # More than one match
      if ((${#imgs[@]} > 1)); then
          echo -e "${RED}Error: Multiple IMG files found in $INSTALL_DIR:${NOCOLOR}"
          for f in "${imgs[@]}"; do
              echo "  $f"
          done
          echo -e "${YELLOW}Please keep only one FarmingSimulator25_*_ESD.img file in the installer directory.${NOCOLOR}"
          exit 1
      fi

      # Exactly one match -> extract that one
      IMG_FILE="${imgs[0]}"
      echo "${GREEN}Using IMG file: $IMG_FILE"
      7z x "$IMG_FILE" -o"$INSTALL_DIR" -y -bso0 -bsp0

      # After extraction, check again
      if [ -f "$INSTALL_DIR/FarmingSimulator2025.exe" ]; then
          INSTALLER_PATH="$INSTALL_DIR/FarmingSimulator2025.exe"
      elif [ -f "$INSTALL_DIR/Setup.exe" ]; then
          INSTALLER_PATH="$INSTALL_DIR/Setup.exe"
      else
          echo -e "${RED}Error: No installer found in $INSTALL_DIR after extraction${NOCOLOR}"
          exit 1
      fi
  fi
  echo -e "${GREEN}INFO: Installer found: $INSTALLER_PATH${NOCOLOR}"
fi

# Extract an IMG/BIN/ZIP flat into $DLC_DIR once.
# Skips extraction if a matching EXE already exists.

declare -a supported_names=()
declare -A seen=()

# Track best source per DLC (prefer exe; otherwise archive)
declare -A dlc_types=()   # name -> exe|archive
declare -A dlc_files=()   # name -> path

# Extract an IMG/BIN/ZIP flat into $DLC_DIR only if no matching EXE exists.
extract_archive_flat_if_needed() {
  local archive="$1"
  local base
  base="$(basename "$archive")"

  if ! command -v 7z >/dev/null 2>&1; then
    echo -e "${RED}ERROR: '7z' (p7zip) is not installed in the container.${NOCOLOR}"
    return 1
  fi

  # Derive the DLC "name" (part after prefix, before first underscore)
  local raw="${base#${DLC_PREFIX}}"
  local dlc_name="${raw%%_*}"

  # If an EXE for this DLC already exists, skip extracting.
  if compgen -G "$DLC_DIR/${DLC_PREFIX}${dlc_name}_*.exe" > /dev/null; then
    echo -e "${GREEN}INFO: EXE for ${dlc_name} already present, skipping extract of ${base}.${NOCOLOR}"
    return 0
  fi

  echo -e "${GREEN}INFO: Extracting ${base} into ${DLC_DIR} ...${NOCOLOR}"
  mkdir -p "$DLC_DIR"

  # Temp dir -> flatten files into $DLC_DIR (no subfolders). Collision-safe moves.
  local tmp_dir
  tmp_dir="$(mktemp -d "/tmp/fs25_pre_${dlc_name}_XXXX")" || {
    echo -e "${RED}ERROR: Cannot create temp dir for ${dlc_name}.${NOCOLOR}"
    return 1
  }

  if ! 7z x -y -o"$tmp_dir" -- "$archive" >/dev/null; then
    echo -e "${RED}ERROR: Extraction failed for ${base}.${NOCOLOR}"
    rm -rf "$tmp_dir"
    return 1
  fi

  while IFS= read -r -d '' f; do
    b="$(basename "$f")"
    dest="${DLC_DIR}/${b}"
    mv "$f" "$dest"
    chmod u+rw "$dest" 2>/dev/null || true
  done < <(find "$tmp_dir" -type f -print0)

  rm -rf "$tmp_dir"
}

# Pre-pass: extract all archives first (so later scan sees any new EXEs)
for a in "$DLC_DIR"/${DLC_PREFIX}*.img "$DLC_DIR"/${DLC_PREFIX}*.IMG \
         "$DLC_DIR"/${DLC_PREFIX}*.zip "$DLC_DIR"/${DLC_PREFIX}*.ZIP; do
  [ -e "$a" ] || continue
  extract_archive_flat_if_needed "$a"
done

# Build list of DLC names (from exe + remaining archives)
for path in "$DLC_DIR"/${DLC_PREFIX}*; do
  [ -e "$path" ] || break
  base="$(basename "$path")"
  ext="${base##*.}"

  case "${ext}" in
    exe|EXE)
      # Example: FarmingSimulator25_highlandsFishingPack_1_1_0_0_ESD.exe
      raw="${base#${DLC_PREFIX}}"   # highlandsFishingPack_1_1_0_0_ESD.exe
      name="${raw%%_*}"             # highlandsFishingPack
      if [[ -z "${seen[$name]:-}" ]]; then
        supported_names+=("$name")
        seen["$name"]=1
      fi
      dlc_types["$name"]="exe"
      dlc_files["$name"]="$path"
      ;;
    img|IMG|zip|ZIP)
      raw="${base#${DLC_PREFIX}}"
      name="${raw%%_*}"
      if [[ -z "${seen[$name]:-}" ]]; then
        supported_names+=("$name")
        seen["$name"]=1
      fi
      # only keep archive if we don't already have an exe
      if [[ "${dlc_types[$name]:-}" != "exe" ]]; then
        dlc_types["$name"]="archive"
        dlc_files["$name"]="$path"
      fi
      ;;
    *)
      # ignore silently
      :
      ;;
  esac
done

# Check DLCs (list what we found and what is installed)
echo -e "${GREEN}INFO: Scanning ${DLC_DIR} for DLC installers...${NOCOLOR}"

if ((${#supported_names[@]})); then
  echo -e "${GREEN}INFO: DLCs found:${NOCOLOR} ${supported_names[*]}"
else
  echo -e "${YELLOW}INFO: No DLC installers (.exe) found in ${DLC_DIR}.${NOCOLOR}"
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

# it's important to check if the config directory exists on the host mount path. If it doesn't exist, create it.

if [ -d "${CONFIG_DIR}" ]; then
  echo -e "${GREEN}INFO: The host config directory exists, no need to create it!${NOCOLOR}"
else
  mkdir -p "${CONFIG_DIR}"
fi

# Required free space in GB
REQUIRED_SPACE=50

. /usr/local/bin/wine_init.sh
. /usr/local/bin/wine_symlinks.sh

# Check if the executable exists
if [ "$GAME_INSTALLED" = false ]; then
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
  cp /opt/fs25/game/Farming\ Simulator\ 2025/VERSION "${CONFIG_DIR}"
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
  echo -e "${YELLOW}No DLC installers to process.${NOCOLOR}"
fi

# Check for updates

echo -e "${YELLOW}INFO: Checking for updates, if you get warning about gpu drivers make sure to click no!${NOCOLOR}"
wine ~/.fs25server/drive_c/Program\ Files\ \(x86\)/Farming\ Simulator\ 2025/FarmingSimulator2025.exe

# Replace VERSION File after update / Create VERSION File after first Install -> fix Version to old error for Future DLCs
cp /opt/fs25/game/Farming\ Simulator\ 2025/VERSION ${CONFIG_DIR}

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
