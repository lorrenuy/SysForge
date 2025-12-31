#!/bin/bash
# SysForge Launcher v0.91 (Fixed: Folder Unwrapping)

REPO_URL="https://github.com/lorrenuy/SysForge.git" 
INSTALL_DIR="/opt/SysForge"
TEMP_DIR="/tmp/sysforge_git_temp"
MAIN_SCRIPT="$INSTALL_DIR/sysforge.sh"
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}>>> SysForge Launcher & Updater${NC}"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then echo "FAIL: Voer dit uit als root (sudo)."; exit 1; fi

# 2. Git Check
if ! command -v git &> /dev/null; then
    echo "Git installeren..."
    if [ -f /etc/debian_version ]; then apt-get update -qq && apt-get install git -y -qq; 
    elif [ -f /etc/arch-release ]; then pacman -S --noconfirm git; fi
fi

echo -e "${GREEN}>>> Downloaden van GitHub...${NC}"

# 3. Downloaden naar tijdelijke map (om dubbele mappen te voorkomen)
if [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi
git clone --quiet "$REPO_URL" "$TEMP_DIR"

# 4. Installeren (De 'SysForge' map uit de temp map verplaatsen naar /opt/)
echo -e "${GREEN}>>> Installeren...${NC}"

# Oude versie verwijderen
if [ -d "$INSTALL_DIR" ]; then rm -rf "$INSTALL_DIR"; fi

# De submap 'SysForge' uit de repo pakken en op de juiste plek zetten
if [ -d "$TEMP_DIR/SysForge" ]; then
    mv "$TEMP_DIR/SysForge" "/opt/"
else
    # Fallback: Als de repo structuur ooit verandert en bestanden direct in de root staan
    mv "$TEMP_DIR" "$INSTALL_DIR"
fi

# Opruimen
rm -rf "$TEMP_DIR"

# 5. Rechten & Starten
if [ -f "$MAIN_SCRIPT" ]; then
    chmod +x "$MAIN_SCRIPT" "$INSTALL_DIR/modules/"*.sh
    echo -e "${BLUE}>>> Starten...${NC}"
    bash "$MAIN_SCRIPT"
else
    echo -e "${RED}FOUT: Kan $MAIN_SCRIPT niet vinden na installatie.${NC}"
    echo "Controleer de mappenstructuur op GitHub."
    ls -R /opt/SysForge
    exit 1
fi
