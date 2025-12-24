#!/bin/bash
fix_broken_mirrors() {
    echo -e "${RED}!!! UPDATE MISLUKT !!!${NC}"; read -p "   Reset mirrors? (J/n): " FIX
    if [[ "$FIX" =~ ^[jJ] ]] || [ -z "$FIX" ]; then 
        if [ -f /etc/apt/sources.list ]; then sudo sed -i 's|https\?://[^ ]*/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list 2>/dev/null; fi
        if [ -f /etc/apt/sources.list.d/system.sources ]; then sudo sed -i 's|URIs: http.*ubuntu.*|URIs: http://archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list.d/system.sources; fi
        msg_ok "Mirrors gereset."; task_update
    fi
}
task_update() { 
    if [ "$SYSTEM_TYPE" == "debian" ] && command -v nala &>/dev/null; then execute_with_progress "Mirrors" "sudo nala fetch --auto -y"; fi
    task_backup
    if [ "$SYSTEM_TYPE" == "debian" ]; then execute_with_progress "Pre-config" "sudo dpkg --configure -a && $CMD_INSTALL software-properties-common wget gpg curl"; fi
    echo -e "${BLUE}🚀 Start Systeem Updates...${NC}"; eval "$CMD_UPDATE"; if [ $? -ne 0 ]; then fix_broken_mirrors; fi
    if command -v flatpak &>/dev/null; then echo -e "${BLUE}📦 Start Flatpak Updates...${NC}"; flatpak update -y --system; flatpak uninstall --unused -y --system; fi
}
