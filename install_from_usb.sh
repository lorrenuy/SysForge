#!/bin/bash
USB_SOURCE="$(dirname "$(readlink -f "$0")")/SysForge"
LOCAL_TARGET="/opt/SysForge"
GREEN='\033[0;32m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo "Run as root."; exit 1; fi
if [ ! -d "$USB_SOURCE" ]; then echo "Folder 'SysForge' not found on USB."; exit 1; fi
if [ -d "$LOCAL_TARGET" ]; then rm -rf "$LOCAL_TARGET"; fi

echo "Copying from USB..."
cp -rp "$USB_SOURCE" "$LOCAL_TARGET"
chmod +x "$LOCAL_TARGET/sysforge.sh" "$LOCAL_TARGET/modules/"*.sh

echo -e "${GREEN}>>> Done. Starting...${NC}"
bash "$LOCAL_TARGET/sysforge.sh"
