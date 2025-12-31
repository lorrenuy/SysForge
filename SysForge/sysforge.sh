#!/bin/bash
# ==============================================================================
#  SysForge Main Controller (v0.90)
# ==============================================================================

# 1. Definieer paden
BASE_DIR=$(dirname "$(readlink -f "$0")")
MODULE_DIR="$BASE_DIR/modules"
CONFIG_FILE="$BASE_DIR/sysforge.conf"

# 2. Laad Config & Modules
if [ -f "$CONFIG_FILE" ]; then source "$CONFIG_FILE"; fi

load_module() { 
    if [ -f "$1" ]; then 
        source "$1"
    else 
        echo "ERR: Critical module missing: $1"
        exit 1
    fi 
}

# Laad alle bouwstenen
load_module "$MODULE_DIR/core.sh"
load_module "$MODULE_DIR/updates.sh"
load_module "$MODULE_DIR/apps.sh"
load_module "$MODULE_DIR/gaming.sh"
load_module "$MODULE_DIR/cloud.sh"
load_module "$MODULE_DIR/advanced.sh"

# 3. Initialisatie (Opstart checks)
detect_distro
detect_desktop_environment
check_internet

# EERST de omgeving klaarmaken (maakt logs map aan)
prepare_environment

# DAN PAS loggen (anders error: map bestaat niet)
log_action "Start"

# DAN de versie check
check_version_integrity

# --- VERSIE CONTROLE (FAIL-SAFE) ---
# Checkt of GitHub nieuwere code heeft en waarschuwt bij lokale wijzigingen
check_version_integrity
# -----------------------------------

# 4. Hoofdmenu Loop
while true; do
    draw_header
    
    # Check: Draaien we vanaf een USB stick in Live mode?
    if is_live_environment; then 
        echo -e "${YELLOW}--- LIVE RECOVERY MODE ---${NC}"
        echo "   1) 🔙 Herstel Systeem (via Cloud Backup)"
        echo "   2) 🚀 Setup Testen (Zonder installatie)"
        echo "   0) ❌ Sluit"
        read -p "   Keuze: " C
        
        case $C in 
            1) restore_from_cloud ;; 
            2) start_setup_wizard; task_update ;; 
            0) break ;; 
        esac
    else 
        # Normale modus (Geïnstalleerd systeem)
        echo -e "${GREEN}--- ONDERHOUD & SETUP ---${NC}"
        echo "   1) 🚀 SysForge Setup (Wizard & Installatie)"
        echo "   2) 🔄 Update Systeem & Flatpaks"
        echo "   3) 📦 Software Center (Apps beheren)"
        echo "   4) 🛡️ Security Check"
        echo "   5) 🧹 Opruimen & Schoonmaken"
        
        echo -e "${BLUE}--- TOOLS ---${NC}"
        echo "   6) 🛠️  Geavanceerde Tools (Repair/Wipe/Cloud)"
        
        # Kiosk mode opties (alleen tonen indien geconfigureerd)
        if [ "$ENABLE_KIOSK_MODE" = true ]; then 
            echo -e "${YELLOW}--- KIOSK ---${NC}"
            echo "   7) Installeer Kiosk"
            echo "   8) Verwijder Kiosk"
        fi
        
        echo ""
        echo "   0) ❌ Sluit"
        read -p "   Keuze: " C
        
        case $C in 
            1) 
                # De volledige installatie cyclus
                start_setup_wizard
                task_apps
                # task_security_check (als die functie bestaat in apps/core)
                # task_cleanup (als die functie bestaat)
                task_backup
                read -p "   Installatie voltooid. Druk op Enter..." 
                ;; 
            2) 
                task_update
                task_backup
                read -p "   Update voltooid. Druk op Enter..." 
                ;; 
            3) 
                menu_software_center 
                ;; 
            4) 
                # Beveiliging check (placeholder als functie nog niet bestaat in modules)
                if command -v task_security_check &>/dev/null; then task_security_check; else echo "Security module check..."; fi
                read -p "   Klaar. Druk op Enter..." 
                ;; 
            5) 
                task_backup
                # task_cleanup (placeholder)
                if command -v task_cleanup &>/dev/null; then task_cleanup; else sudo apt autoremove -y; fi
                read -p "   Schoongemaakt. Druk op Enter..." 
                ;; 
            6) 
                menu_advanced_tools 
                ;; 
            7) 
                if [ "$ENABLE_KIOSK_MODE" = true ]; then install_kiosk; fi 
                ;; 
            8) 
                if [ "$ENABLE_KIOSK_MODE" = true ]; then remove_delijn_kiosk; fi 
                ;; 
            0) 
                break 
                ;; 
            *)
                echo "   Ongeldige keuze."
                sleep 1
                ;;
        esac
    fi
done
