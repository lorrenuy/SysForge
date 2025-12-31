#!/bin/bash
# SysForge Launcher v0.92 (Auto-Unpack Fix)

REPO_URL="https://github.com/lorrenuy/SysForge.git" 
INSTALL_DIR="/opt/SysForge"
TEMP_GIT_DIR="/tmp/sysforge_git_temp"
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${BLUE}>>> SysForge Installer & Launcher${NC}"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then echo "FAIL: Run as root."; exit 1; fi

# 2. Git Check
if ! command -v git &> /dev/null; then
    echo "Git installeren..."
    if [ -f /etc/debian_version ]; then apt-get update -qq && apt-get install git -y -qq; 
    elif [ -f /etc/arch-release ]; then pacman -S --noconfirm git; fi
fi

# 3. Downloaden (Altijd vers via een tijdelijke map)
echo -e "${GREEN}>>> Downloaden van GitHub...${NC}"
if [ -d "$TEMP_GIT_DIR" ]; then rm -rf "$TEMP_GIT_DIR"; fi
git clone --quiet "$REPO_URL" "$TEMP_GIT_DIR"

# 4. Installeren (De 'SysForge' submap eruit vissen)
echo -e "${GREEN}>>> Installeren...${NC}"

# Oude installatie verwijderen om conflicten te voorkomen
if [ -d "$INSTALL_DIR" ]; then rm -rf "$INSTALL_DIR"; fi

# HIER ZIT DE FIX:
# We kijken of de repo een submap 'SysForge' heeft (de nieuwe structuur)
if [ -d "$TEMP_GIT_DIR/SysForge" ]; then
    # Ja: Verplaats alleen die submap naar /opt/SysForge
    mv "$TEMP_GIT_DIR/SysForge" "$INSTALL_DIR"
else
    # Nee: De repo is plat (fallback), verplaats alles
    mv "$TEMP_GIT_DIR" "$INSTALL_DIR"
fi

# Opruimen temp
rm -rf "$TEMP_GIT_DIR"

# 5. Starten
MAIN_SCRIPT="$INSTALL_DIR/sysforge.sh"

if [ -f "$MAIN_SCRIPT" ]; then
    chmod +x "$MAIN_SCRIPT" "$INSTALL_DIR/modules/"*.sh
    echo -e "${BLUE}>>> Starten...${NC}"
    echo ""
    bash "$MAIN_SCRIPT"
else
    echo -e "${RED}CRITIAL ERROR: Kan $MAIN_SCRIPT niet vinden!${NC}"
    echo "Huidige inhoud van /opt/:"
    ls -R /opt/SysForge
    exit 1
fi
