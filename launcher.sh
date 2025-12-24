#!/bin/bash
REPO_URL="https://github.com/lorrenuy/SysForge.git" 
INSTALL_DIR="/opt/SysForge"
MAIN_SCRIPT="$INSTALL_DIR/sysforge.sh"
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo "Run as root."; exit 1; fi
if ! command -v git &> /dev/null; then
    if [ -f /etc/debian_version ]; then apt-get update -qq && apt-get install git -y -qq; 
    elif [ -f /etc/arch-release ]; then pacman -S --noconfirm git; fi
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "${GREEN}>>> Updating...${NC}"
    cd "$INSTALL_DIR"; git fetch --all; git reset --hard origin/main; git pull
else
    echo -e "${GREEN}>>> Installing...${NC}"
    rm -rf "$INSTALL_DIR"; git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$MAIN_SCRIPT" "$INSTALL_DIR/modules/"*.sh
bash "$MAIN_SCRIPT"
