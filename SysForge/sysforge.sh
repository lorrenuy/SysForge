#!/bin/bash
BASE_DIR=$(dirname "$(readlink -f "$0")")
MODULE_DIR="$BASE_DIR/modules"
CONFIG_FILE="$BASE_DIR/sysforge.conf"
if [ -f "$CONFIG_FILE" ]; then source "$CONFIG_FILE"; fi
load_module() { if [ -f "$1" ]; then source "$1"; else echo "ERR: $1 missing"; exit 1; fi; }

load_module "$MODULE_DIR/core.sh"
load_module "$MODULE_DIR/updates.sh"
load_module "$MODULE_DIR/apps.sh"
load_module "$MODULE_DIR/gaming.sh"
load_module "$MODULE_DIR/cloud.sh"
load_module "$MODULE_DIR/advanced.sh"

log_action "Start"
detect_distro; detect_desktop_environment; check_internet; prepare_environment

while true; do
    draw_header
    if is_live_environment; then 
        echo "   1) 🔙 Herstel"; echo "   2) 🚀 Setup Test"; echo "   0) ❌ Sluit"; read -p "   : " C
        case $C in 1) restore_from_cloud ;; 2) start_setup_wizard; task_update ;; 0) break ;; esac
    else 
        echo -e "${GREEN}--- ONDERHOUD ---${NC}"
        echo "   1) 🚀 SysForge Setup"; echo "   2) 🔄 Update + Backup"
        echo "   3) 📦 Software Center"; echo "   4) 🛡️ Sec Check"; echo "   5) 🧹 Clean"
        echo -e "${BLUE}--- TOOLS ---${NC}"; echo "   6) 🛠️  Advanced Tools"
        echo ""; if [ "$ENABLE_KIOSK_MODE" = true ]; then echo -e "${YELLOW}--- KIOSK ---${NC}"; echo "   7) Install"; echo "   8) Remove"; echo ""; fi
        echo "   0) ❌ Sluit"; read -p "   : " C
        case $C in 
            1) start_setup_wizard; task_apps; task_security_check; task_cleanup; task_backup; task_cloud_setup "MANUAL"; read -p "   Klaar..." ;; 
            2) task_update; task_security_check; task_backup; read -p "   Klaar..." ;; 
            3) menu_software_center ;; 4) task_security_check; read -p "   Klaar..." ;; 5) task_backup; task_cleanup; read -p "   Klaar..." ;; 
            6) menu_advanced_tools ;; 7) if [ "$ENABLE_KIOSK_MODE" = true ]; then install_kiosk; fi ;; 8) if [ "$ENABLE_KIOSK_MODE" = true ]; then remove_delijn_kiosk; fi ;; 
            0) break ;; 
        esac
    fi
done
