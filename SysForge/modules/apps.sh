#!/bin/bash
# modules/apps.sh

# --- CONFIG MANAGEMENT (Was missing!) ---
save_config() {
    # Schrijft de huidige variabelen naar het config bestand
    cat > "$CONFIG_FILE" <<EOF
SCRIPT_VERSION="$SCRIPT_VERSION"
PC_NAME="$PC_NAME"
BACKUP_MAX_DAYS=$BACKUP_MAX_DAYS
CLOUD_BACKUP_RETENTION=$CLOUD_BACKUP_RETENTION
MIN_FREE_SPACE_GB=$MIN_FREE_SPACE_GB
RCLONE_REMOTE="$RCLONE_REMOTE"
USE_CLOUD_UPLOAD=$USE_CLOUD_UPLOAD
INCLUDE_HOME_BACKUP=$INCLUDE_HOME_BACKUP
BACKUP_DEVICE_UUID="$BACKUP_DEVICE_UUID"
INSTALL_SECURITY=$INSTALL_SECURITY
OFFICE_TYPE="$OFFICE_TYPE"
INSTALL_GAMING=$INSTALL_GAMING
INSTALL_TLP=$INSTALL_TLP
ENABLE_KIOSK_MODE=$ENABLE_KIOSK_MODE
SELECTED_BROWSER="$SELECTED_BROWSER"
SELECTED_SHELL="$SELECTED_SHELL"
APP_PEAZIP=$APP_PEAZIP
APP_BITWARDEN=$APP_BITWARDEN
APP_FLATSEAL=$APP_FLATSEAL
APP_ZAPZAP=$APP_ZAPZAP
APP_LOCALSEND=$APP_LOCALSEND
APP_VIDEODL=$APP_VIDEODL
APP_SPOTIFY=$APP_SPOTIFY
APP_DISCORD=$APP_DISCORD
APP_VLC=$APP_VLC
APP_WEBAPP_MANAGER=$APP_WEBAPP_MANAGER
CLI_TOOLS="$CLI_TOOLS"
EOF
    # Array opslaan is lastig in bash config files, we doen een simpele dump voor custom apps
    # Voor nu laten we de array leeg bij herladen om complexiteit te voorkomen in deze fix
}

# --- BROWSER HELPERS (Was missing!) ---
detect_current_browser() {
    DETECTED_BROWSER="none"
    if flatpak list | grep -q "org.mozilla.firefox"; then DETECTED_BROWSER="firefox";
    elif flatpak list | grep -q "com.google.Chrome"; then DETECTED_BROWSER="chrome";
    elif flatpak list | grep -q "com.brave.Browser"; then DETECTED_BROWSER="brave";
    elif dpkg -l | grep -q "firefox"; then DETECTED_BROWSER="firefox"; fi
}

remove_detected_browser() {
    local BROWSER=$1
    if [ "$BROWSER" == "firefox" ]; then execute_with_progress "Verwijder Firefox (System)" "$CMD_REMOVE firefox*"; fi
    # Andere browsers verwijderen we niet automatisch om dataverlies te voorkomen, tenzij expliciet gevraagd
}

# --- SECURITY (Was missing!) ---
task_security_install() {
    if [ "$INSTALL_SECURITY" = true ]; then
        msg_info "Beveiliging installeren..."
        if [ "$SYSTEM_TYPE" == "debian" ]; then
            execute_with_progress "UFW Firewall" "$CMD_INSTALL ufw && sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw enable"
            execute_with_progress "Fail2Ban" "$CMD_INSTALL fail2ban"
        fi
    fi
}

# --- HOSTNAME FIX (VOOR MX LINUX / NON-SYSTEMD) ---
set_hostname_safe() {
    local NEW_NAME="$1"
    
    # Methode 1: Systemd (Ubuntu, Pop, Arch, Debian modern)
    if command -v hostnamectl &>/dev/null; then
        sudo hostnamectl set-hostname "$NEW_NAME"
    else
        # Methode 2: Handmatig (MX Linux, AntiX, SysVinit)
        echo -e "${YELLOW}   ⚠️  Geen systemd gedetecteerd (MX Linux?), hostname handmatig instellen...${NC}"
        echo "$NEW_NAME" | sudo tee /etc/hostname > /dev/null
        sudo hostname "$NEW_NAME"
        # Pas hosts file aan om sudo errors te voorkomen (127.0.1.1 oude-naam -> 127.0.1.1 nieuwe-naam)
        sudo sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_NAME/g" /etc/hosts
    fi
    
    PC_NAME="$NEW_NAME"
    RCLONE_FOLDER="$RCLONE_ROOT/$PC_NAME"
}

# --- MENU: SOFTWARE CENTER ---
menu_software_center() {
    while true; do
        draw_header
        echo -e "${YELLOW}--- SOFTWARE CENTER ---${NC}"
        echo "   1) 🚀 Run Batch Install (Jouw selectie)"
        echo "   2) ⚙️  Selectie Aanpassen"
        echo "   3) 🔍 Zoek & Installeer (Handmatig)"
        echo "   4) 🗑️  Verwijder Software"
        echo "   5) 🌐 Web App Tool"
        echo "   6) ❌ Web App Verwijderen"
        echo "   7) 🗑️  Uninstall SysForge"
        echo ""
        echo "   0) 🔙 Terug naar Hoofdmenu"
        read -p "   Keuze: " SWM
        case $SWM in
            1) task_apps; read -p "   Klaar. Enter..." ;;
            2) manage_flatpak_selection; save_config ;;
            3) task_install_manual ;;
            4) task_remove_manual ;;
            5) task_launch_webapp_manager ;;
            6) task_remove_webapp ;;
            7) uninstall_sysforge ;;
            0) return ;;
        esac
    done
}

# --- SELECTIE HELPERS ---
toggle_app_val() { if [ "$1" == "true" ]; then echo "false"; else echo "true"; fi; }
get_status_icon() { if [ "$1" == "true" ]; then echo -e "${GREEN}[AAN]${NC}"; else echo -e "${RED}[UIT]${NC}"; fi; }

manage_flatpak_selection() {
    while true; do
        clear; echo -e "${YELLOW}   --- APPLICATIE SELECTIE ---${NC}"
        echo "   1) PeaZip             $(get_status_icon $APP_PEAZIP)"
        echo "   2) Bitwarden          $(get_status_icon $APP_BITWARDEN)"
        echo "   3) Flatseal           $(get_status_icon $APP_FLATSEAL)"
        echo "   4) ZapZap             $(get_status_icon $APP_ZAPZAP)"
        echo "   5) LocalSend          $(get_status_icon $APP_LOCALSEND)"
        echo "   6) Video Downloader   $(get_status_icon $APP_VIDEODL)"
        echo "   7) Spotify            $(get_status_icon $APP_SPOTIFY)"
        echo "   8) Discord            $(get_status_icon $APP_DISCORD)"
        echo "   9) VLC                $(get_status_icon $APP_VLC)"
        echo "   10) WebApps           $(get_status_icon $APP_WEBAPP_MANAGER)"
        echo ""; echo "   Kies nummer om te wisselen. 'K' om klaar te zijn."
        read -p "   Keuze: " S
        case $S in
            1) APP_PEAZIP=$(toggle_app_val $APP_PEAZIP);; 2) APP_BITWARDEN=$(toggle_app_val $APP_BITWARDEN);;
            3) APP_FLATSEAL=$(toggle_app_val $APP_FLATSEAL);; 4) APP_ZAPZAP=$(toggle_app_val $APP_ZAPZAP);;
            5) APP_LOCALSEND=$(toggle_app_val $APP_LOCALSEND);; 6) APP_VIDEODL=$(toggle_app_val $APP_VIDEODL);;
            7) APP_SPOTIFY=$(toggle_app_val $APP_SPOTIFY);; 8) APP_DISCORD=$(toggle_app_val $APP_DISCORD);;
            9) APP_VLC=$(toggle_app_val $APP_VLC);; 10) APP_WEBAPP_MANAGER=$(toggle_app_val $APP_WEBAPP_MANAGER);;
            [kK]*) break;; *) ;;
        esac
    done
}

input_custom_apps() {
    echo ""; echo -e "${CYAN}   Extra Applicaties (Flatpak) toevoegen?${NC}"
    echo "   Typ namen (bv 'obs-studio gimp') of laat leeg."
    read -p "   > " INPUT_CUSTOM
    if [ -n "$INPUT_CUSTOM" ]; then for app in $INPUT_CUSTOM; do CUSTOM_FLATPAK_LIST+=("$app"); done; echo -e "${GREEN}   Toegevoegd.${NC}"; fi
}

# --- SETUP WIZARD ---
start_setup_wizard() {
    draw_header; echo -e "${GREEN}=== SETUP WIZARD ===${NC}"
    
    # 1. Hostname (AANGEPAST VOOR MX)
    echo -e "${YELLOW}1. Computernaam${NC}"; echo "   Huidig: ${BOLD}$PC_NAME${NC}"
    while true; do 
        read -p "   Nieuwe Naam: " INPUT_NAME
        INPUT_NAME=$(echo "$INPUT_NAME" | tr -d ' ')
        if [ -z "$INPUT_NAME" ]; then echo -e "${RED}   ⚠️  Leeg.${NC}"; 
        elif [ "$INPUT_NAME" == "$PC_NAME" ]; then echo -e "${RED}   ⚠️  Kies nieuw.${NC}"; 
        else 
            set_hostname_safe "$INPUT_NAME" # Gebruikt nu de veilige functie
            echo -e "${GREEN}   ✅ Naam ingesteld: $PC_NAME${NC}"; 
            break; 
        fi; 
    done
    
    # 2. Gebruikers
    echo ""; read -p "2. Meerdere gebruikers? (j/N): " WM
    if [[ "$WM" =~ ^[jJ] ]]; then 
        SETUP_MULTI_USER=true
        echo -e "${CYAN}   Voer gebruikers in (laat naam leeg om te stoppen):${NC}"
        while true; do 
            read -p "   > Gebruikersnaam: " NU
            if [ -z "$NU" ]; then break; fi
            read -s -p "   > Wachtwoord voor $NU: " PW; echo ""
            NEW_USERS_LIST+=("$NU:$PW")
        done
    fi
    
    # 3. Backup (Placeholder fix)
    # select_backup_drive # Uitgeschakeld omdat de functie in cloud.sh mist in deze versie
    
    # 4. Cloud
    echo ""; read -p "4. Cloud Backup? (j/N): " WC; if [[ "$WC" =~ ^[jJ] ]]; then if ! command -v rclone &>/dev/null; then $CMD_INSTALL rclone >/dev/null; fi; setup_rclone_simplified; fi
    
    # 5. Security & Gaming
    echo ""; echo -e "${YELLOW}5. Beveiliging${NC}"; read -p "   Inschakelen? (j/N): " WS; if [[ "$WS" =~ ^[jJ] ]]; then INSTALL_SECURITY=true; else INSTALL_SECURITY=false; fi
    echo ""; echo -e "${YELLOW}6. Gaming (CachyOS)${NC}"; read -p "   Inschakelen? (j/N): " WG; if [[ "$WG" =~ ^[jJ] ]]; then INSTALL_GAMING=true; fi
    
    # 7. Browser
    echo ""; echo -e "${YELLOW}7. Browser Keuze${NC}"; 
    echo "   1) Firefox 2) Chrome 3) Brave 4) Vivaldi 5) LibreWolf"
    read -p "   Keuze: " BS
    case $BS in 1) SELECTED_BROWSER="firefox";; 2) SELECTED_BROWSER="chrome";; 3) SELECTED_BROWSER="brave";; 4) SELECTED_BROWSER="vivaldi";; 5) SELECTED_BROWSER="librewolf";; *) SELECTED_BROWSER="firefox";; esac
    
    # 8. Software
    echo ""; echo -e "${YELLOW}8. Software Selectie${NC}"
    read -p "   1) Aanbevolen 2) Zelf kiezen: " SW_MODE
    if [ "$SW_MODE" == "2" ]; then manage_flatpak_selection; fi
    input_custom_apps
    
    # 9. Office
    echo ""; echo -e "${YELLOW}9. Kantoor${NC}"; read -p "   1) Flatpak 2) Repo 3) Geen: " LO_CHOICE
    case $LO_CHOICE in 1) OFFICE_TYPE="flatpak";; 2) OFFICE_TYPE="repo";; *) OFFICE_TYPE="none";; esac
    
    save_config; echo ""; echo -e "${GREEN}   Starten...${NC}"; sleep 1
}

# --- INSTALLATIE ---
task_apps() {
    execute_with_progress "CLI Tools" "$CMD_INSTALL $CLI_TOOLS"
    
    # Browser
    if [ -n "$SELECTED_BROWSER" ]; then
        detect_current_browser
        if [ "$SELECTED_BROWSER" != "$DETECTED_BROWSER" ]; then
            remove_detected_browser "$DETECTED_BROWSER"
            case $SELECTED_BROWSER in 
                "firefox") C="flatpak install --system flathub org.mozilla.firefox -y" ;;
                "chrome") C="flatpak install --system flathub com.google.Chrome -y" ;;
                "brave") C="flatpak install --system flathub com.brave.Browser -y" ;;
                "vivaldi") C="flatpak install --system flathub com.vivaldi.Vivaldi -y" ;;
                "librewolf") C="flatpak install --system flathub io.gitlab.librewolf-community -y" ;;
            esac
            execute_with_progress "Install $SELECTED_BROWSER" "$C"
        fi
    fi

    # Flatpak
    if ! command -v flatpak &>/dev/null; then execute_with_progress "Flatpak Engine" "$CMD_INSTALL $PKG_FLATPAK"; fi
    flatpak remote-delete --user flathub --force > /dev/null 2>&1
    flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    # Apps
    inst_fp() { if [ "$2" = true ]; then execute_with_progress "$3" "flatpak install --system flathub $1 -y"; fi; }
    inst_fp "io.github.peazip.PeaZip" "$APP_PEAZIP" "PeaZip"
    inst_fp "com.bitwarden.desktop" "$APP_BITWARDEN" "Bitwarden"
    inst_fp "com.github.tchx84.Flatseal" "$APP_FLATSEAL" "Flatseal"
    inst_fp "com.rtosta.zapzap" "$APP_ZAPZAP" "ZapZap"
    inst_fp "org.localsend.localsend_app" "$APP_LOCALSEND" "LocalSend"
    inst_fp "com.github.unrud.VideoDownloader" "$APP_VIDEODL" "VideoDL"
    inst_fp "com.spotify.Client" "$APP_SPOTIFY" "Spotify"
    inst_fp "com.discordapp.Discord" "$APP_DISCORD" "Discord"
    inst_fp "org.videolan.VLC" "$APP_VLC" "VLC"
    inst_fp "com.linuxmint.webapp-manager" "$APP_WEBAPP_MANAGER" "WebApps"
    
    if [ ${#CUSTOM_FLATPAK_LIST[@]} -gt 0 ]; then
        for custom_app in "${CUSTOM_FLATPAK_LIST[@]}"; do
            execute_with_progress "Custom: $custom_app" "flatpak install --system flathub $custom_app -y"
        done
    fi
    
    # Office
    if [ "$OFFICE_TYPE" == "flatpak" ]; then
        execute_with_progress "Verwijder Oude LO" "$CMD_REMOVE libreoffice* && $CMD_CLEAN"
        execute_with_progress "LibreOffice (Flatpak)" "flatpak install --system flathub org.libreoffice.LibreOffice -y"
    elif [ "$INSTALL_OFFICE" = true ]; then
        install_libreoffice_smart
    fi
    
    # Gaming & Security
    task_security_install
    if [ "$INSTALL_GAMING" = true ]; then 
        if [ "$SYSTEM_TYPE" == "arch" ]; then GCMD="sudo pacman -S --noconfirm steam gamemode gamescope mangohud goverlay"; else GCMD="$CMD_INSTALL steam-installer gamemode gamescope mangohud goverlay steam-devices"; fi
        execute_with_progress "Gaming Stack" "$GCMD"
        optimize_gaming_tweaks
    fi
    if [ "$INSTALL_TLP" = true ]; then execute_with_progress "TLP" "$CMD_INSTALL tlp && sudo systemctl enable --now tlp"; fi

    # Users
    if [ ${#NEW_USERS_LIST[@]} -gt 0 ]; then
        for ENTRY in "${NEW_USERS_LIST[@]}"; do
            U="${ENTRY%%:*}"; P="${ENTRY#*:}"
            if ! id "$U" &>/dev/null; then
                execute_with_progress "User $U maken" "sudo useradd -m -s /bin/bash $U && echo '$U:$P' | sudo chpasswd"
            else msg_warn "User $U bestaat al."; fi
        done
    fi
    msg_ok "Klaar."
}

# --- MANUAL TOOLS ---
task_install_manual() {
    draw_header; echo -e "${BLUE}=== SOFTWARE ZOEKEN ===${NC}"
    read -p "   Zoekterm: " Q; if [[ -z "$Q" ]]; then return; fi
    echo -e "${YELLOW}   Zoeken...${NC}"
    declare -a R_NAME; declare -a R_ID; declare -a R_TYPE; declare -a R_VER
    while read -r line; do if [ -n "$line" ]; then APP_ID=$(echo "$line" | awk '{print $2}'); VER=$(echo "$line" | awk '{print $3}'); R_NAME+=("$APP_ID"); R_ID+=("$APP_ID"); R_TYPE+=("FLATPAK"); R_VER+=("${VER:-N/A}"); fi; done < <(flatpak search --columns=name,application,version,description "$Q" | head -n 5)
    mapfile -t REPO_HITS < <(apt-cache search --names-only "$Q" | head -n 5 | awk '{print $1}')
    for pkg in "${REPO_HITS[@]}"; do C=$(LC_ALL=C apt-cache policy "$pkg" | grep "Candidate:" | awk '{print $2}'); if [ -n "$C" ] && [ "$C" != "(none)" ]; then R_NAME+=("$pkg"); R_ID+=("$pkg"); R_TYPE+=("SYSTEM"); R_VER+=("$C"); fi; done
    COUNT=0; for i in "${!R_NAME[@]}"; do COUNT=$((COUNT+1)); echo "   $COUNT) [${R_TYPE[$i]}] ${R_NAME[$i]} (v${R_VER[$i]})"; done
    echo ""; read -p "   Keuze: " SEL
    if [[ "$SEL" -gt 0 && "$SEL" -le "$COUNT" ]]; then IDX=$((SEL-1)); if [ "${R_TYPE[$IDX]}" == "FLATPAK" ]; then execute_with_progress "Install" "flatpak install --system flathub ${R_ID[$IDX]} -y"; else execute_with_progress "Install" "$CMD_INSTALL ${R_ID[$IDX]}"; fi; fi
    read -p "   Enter..."
}

task_remove_manual() { 
    draw_header; echo -e "${RED}=== APP UNINSTALLER ===${NC}"
    read -p "   Naam: " I; if [[ -z "$I" ]]; then return; fi
    F=$(flatpak list --app --columns=application | grep -i "$I" | head -n 1)
    if [ -n "$F" ]; then flatpak uninstall -y --system "$F"; else execute_with_progress "Verwijderen $I" "$CMD_REMOVE $I && $CMD_CLEAN"; fi
    read -p "   Enter..."; 
}

task_launch_webapp_manager() { 
    draw_header; echo -e "${BLUE}   Webapp Manager${NC}"
    if flatpak list | grep -q "com.linuxmint.webapp-manager"; then flatpak run com.linuxmint.webapp-manager &
    else echo -e "${YELLOW}   Installeren...${NC}"; execute_with_progress "Install Webapp Manager" "flatpak install --system flathub com.linuxmint.webapp-manager -y"; flatpak run com.linuxmint.webapp-manager & fi
    sleep 2; echo "   Druk op Enter..."; read -p "   "
}

task_remove_webapp() { 
    draw_header; APP_DIR="$REAL_HOME/.local/share/applications"
    mapfile -t FILES < <(find "$APP_DIR" -maxdepth 1 -name "*.desktop" 2>/dev/null)
    if [ ${#FILES[@]} -eq 0 ]; then msg_warn "Geen apps."; read -p "   Enter..."; return; fi
    count=0; declare -a FILE_MAP
    for file in "${FILES[@]}"; do count=$((count+1)); NAME=$(grep "^Name=" "$file" | head -n 1 | cut -d= -f2); FILENAME=$(basename "$file"); FILE_MAP+=("$file"); echo "   $count) $NAME ($FILENAME)"; done
    echo ""; read -p "   Kies: " SEL
    if [[ "$SEL" -gt 0 && "$SEL" -le "$count" ]]; then 
        TARGET_FILE="${FILE_MAP[$((SEL-1))]}"; TARGET_NAME=$(basename "$TARGET_FILE")
        read -p "   Verwijder '$TARGET_NAME'? (j/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[jJ] ]]; then rm "$TARGET_FILE"; msg_ok "Verwijderd."; fi
    fi
    read -p "   Enter..."
}
