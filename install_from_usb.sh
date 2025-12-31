#!/bin/bash
# SysForge USB Installer v0.91

# We gaan ervan uit dat dit script NAAST de map 'SysForge' staat op de USB
USB_DIR="$(dirname "$(readlink -f "$0")")"
USB_SOURCE="$USB_DIR/SysForge"
LOCAL_TARGET="/opt/SysForge"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo "Run as root."; exit 1; fi

echo -e "${BLUE}>>> USB Installatie${NC}"

# Check of de bronmap bestaat
if [ ! -d "$USB_SOURCE" ]; then
    echo -e "${RED}FOUT: Map 'SysForge' niet gevonden op USB.${NC}"
    echo "Gezocht in: $USB_SOURCE"
    exit 1
fi

echo ">>> Kopiëren naar $LOCAL_TARGET..."

# Oude versie weg
if [ -d "$LOCAL_TARGET" ]; then rm -rf "$LOCAL_TARGET"; fi

# Kopiëren
cp -rp "$USB_SOURCE" "$LOCAL_TARGET"

# Rechten
chmod +x "$LOCAL_TARGET/sysforge.sh"
chmod +x "$LOCAL_TARGET/modules/"*.sh

# Starten
if [ -f "$LOCAL_TARGET/sysforge.sh" ]; then
    echo -e "${GREEN}>>> Starten...${NC}"
    bash "$LOCAL_TARGET/sysforge.sh"
else
    echo -e "${RED}FOUT: Bestand sysforge.sh niet gevonden in $LOCAL_TARGET.${NC}"
    exit 1
fi
