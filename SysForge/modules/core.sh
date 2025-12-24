#!/bin/bash
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
is_live_environment() { if grep -qE "boot=casper|boot=live|live-media" /proc/cmdline; then return 0; fi; return 1; }
prepare_environment() {
    if is_live_environment; then LOG_FILE="/tmp/sysforge_live.log"; return; fi
    if [ ! -d "$LOG_DIR" ]; then mkdir -p "$LOG_DIR"; chown "$REAL_USER":"$REAL_USER" "$LOG_DIR"; fi
    if [ ! -f "$LOG_FILE" ]; then touch "$LOG_FILE"; chown "$REAL_USER":"$REAL_USER" "$LOG_FILE"; fi
}
log_action() { local m="$1"; local t=$(date "+%Y-%m-%d %H:%M:%S"); if ! is_live_environment; then echo "[$t] $m" >> "$LOG_FILE"; fi; }
execute_with_progress() {
    local DESC="$1"; local CMD="$2"; eval "$CMD" > "$TEMP_TASK_LOG" 2>&1 & local PID=$!; tput civis
    local width=20; local i=0; local direction=1; local chars="<=>"
    while ps -p $PID > /dev/null; do
        local bar=""; for ((j=0; j<width; j++)); do if [ $j -eq $i ]; then bar+="$chars"; else bar+=" "; fi; done
        bar="${bar:0:width}"; printf "\r   [${BLUE}%s${NC}] %s" "$bar" "$DESC"
        if [ $direction -eq 1 ]; then ((i++)); if [ $i -ge $((width-3)) ]; then direction=-1; fi; else ((i--)); if [ $i -le 0 ]; then direction=1; fi; fi; sleep 0.1
    done
    tput cnorm; wait $PID; local EC=$?; printf "\r\033[K"
    if [ $EC -eq 0 ]; then echo -e "   ${GREEN}✅ $DESC${NC}"; log_action "OK: $DESC"; else echo -e "   ${RED}❌ $DESC${NC}"; log_action "FAIL: $DESC"; return 1; fi
}
msg_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
msg_ok() { echo -e "${GREEN}✅ $1${NC}"; }
msg_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
msg_err() { echo -e "${RED}❌ $1${NC}"; }
check_disk_space() { local f=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//'); if [ "$f" -lt "$MIN_FREE_SPACE_GB" ]; then msg_err "Schijf vol ($f GB)"; return 1; fi; return 0; }
detect_distro() {
    if [ -f /etc/os-release ]; then . /etc/os-release; DISTRO=$ID; LIKE=$ID_LIKE; fi
    if [[ "$DISTRO" == "debian" || "$LIKE" == *"debian"* || "$LIKE" == *"ubuntu"* ]]; then 
        SYSTEM_TYPE="debian"; export DEBIAN_FRONTEND=noninteractive
        CMD_UPDATE="sudo apt update -qq && sudo apt dist-upgrade -y"; CMD_INSTALL="sudo apt install -y"; CMD_REMOVE="sudo apt remove -y"; CMD_CLEAN="sudo apt autoremove -y && sudo apt autoclean"
        if command -v nala &>/dev/null; then CMD_UPDATE="sudo nala update && sudo nala upgrade -y"; CMD_INSTALL="sudo nala install -y"; CMD_REMOVE="sudo nala remove -y"; CMD_CLEAN="sudo nala autoremove -y && sudo nala clean"; fi
        PKG_FLATPAK="flatpak"; PKG_CLAMAV="clamav clamav-daemon clamtk"
    elif [[ "$DISTRO" == "arch" || "$LIKE" == *"arch"* ]]; then 
        SYSTEM_TYPE="arch"; CMD_UPDATE="sudo pacman -Syu --noconfirm"; CMD_INSTALL="sudo pacman -S --noconfirm --needed"; CMD_REMOVE="sudo pacman -Rs --noconfirm"; CMD_CLEAN="sudo paccache -rk2"; PKG_FLATPAK="flatpak"; PKG_CLAMAV="clamav clamtk"
    elif [[ "$DISTRO" == "fedora" || "$LIKE" == *"fedora"* ]]; then 
        SYSTEM_TYPE="fedora"; CMD_UPDATE="sudo dnf upgrade --refresh -y"; CMD_INSTALL="sudo dnf install -y"; CMD_REMOVE="sudo dnf remove -y"; CMD_CLEAN="sudo dnf clean all"; PKG_FLATPAK="flatpak"; PKG_CLAMAV="clamav clamav-update clamtk"
    fi
}
detect_desktop_environment() { 
    if [ "$XDG_CURRENT_DESKTOP" != "" ]; then CURRENT_DE="$XDG_CURRENT_DESKTOP"; elif [ -f /usr/bin/gnome-shell ]; then CURRENT_DE="GNOME"; elif [ -f /usr/bin/plasmashell ]; then CURRENT_DE="KDE"; elif [ -f /usr/bin/cosmic-session ]; then CURRENT_DE="COSMIC"; elif [ -f /usr/bin/xfce4-session ]; then CURRENT_DE="XFCE"; fi
    if [[ "$CURRENT_DE" == *"Pop"* || "$CURRENT_DE" == *"COSMIC"* ]]; then CURRENT_DE="COSMIC/Pop"; fi
}
check_internet() {
    while true; do
        if ping -q -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then return 0; fi
        echo -e "${RED}   Geen internet.${NC}"; if command -v nmcli &> /dev/null; then if nmcli radio wifi | grep -q "enabled"; then connect_wifi_interactive; fi; fi
        read -p "   Probeer opnieuw (R/x): " RETRY; if [[ "$RETRY" =~ ^[xX] ]]; then exit 1; fi
    done
}
connect_wifi_interactive() {
    mapfile -t SSIDS < <(nmcli -f SSID,BARS device wifi list | grep -v "^--" | grep -v "^SSID" | awk '{$NF=""; print $0}' | sort -u | sed 's/[ \t]*$//' | grep -v "^$")
    echo -e "${YELLOW}   Netwerken:${NC}"; i=1; for ssid in "${SSIDS[@]}"; do echo "   $i) $ssid"; ((i++)); done
    read -p "   Kies: " SEL
    if [[ "$SEL" -gt 0 && "$SEL" -le "${#SSIDS[@]}" ]]; then 
        CHOSEN_SSID="${SSIDS[$((SEL-1))]}"; CHOSEN_SSID=$(echo "$CHOSEN_SSID" | awk '{print $1}')
        read -s -p "   Pass: " PASS; echo ""; execute_with_progress "Verbinden" "nmcli device wifi connect '$CHOSEN_SSID' password '$PASS'"
    fi
}
draw_header() { 
    clear; if is_live_environment; then echo -e "${RED}${BOLD}   >>> LIVE OMGEVING <<<${NC}"; 
    else 
        if [ "$USE_CLOUD_UPLOAD" = true ]; then C_STAT="${GREEN}[AAN]${NC}"; else C_STAT="${RED}[UIT]${NC}"; fi
        echo -e "${CYAN}${BOLD}   SysForge v${SCRIPT_VERSION}${NC} | ${BLUE}$DISTRO${NC} | ${BLUE}$CURRENT_DE${NC} | Cloud: $C_STAT"; echo -e "${CYAN}   ====================================================${NC}"
    fi 
}
