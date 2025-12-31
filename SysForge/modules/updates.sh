#!/bin/bash
# modules/updates.sh

fix_broken_mirrors() {
    echo -e "${RED}!!! UPDATE MISLUKT !!!${NC}"
    echo -e "${YELLOW}   De updateserver reageert niet of is traag.${NC}"
    echo -e "   Gedetecteerde Distro: ${BOLD}$DISTRO${NC}"
    
    read -p "   Probeer servers te herstellen naar fabrieksstandaard? (J/n): " FIX
    if [[ "$FIX" =~ ^[jJ] ]] || [ -z "$FIX" ]; then 
        msg_info "Bezig met herstellen van mirrors..."

        # 1. ARCH LINUX (Reflector)
        if [ "$SYSTEM_TYPE" == "arch" ]; then
            if command -v reflector &> /dev/null; then
                execute_with_progress "Reflector (Fastest Mirrors)" "sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist"
            else
                msg_warn "Installeer 'reflector' om Arch mirrors te fixen."
            fi
            return
        fi

        # 2. FEDORA (Cache Clean)
        if [ "$SYSTEM_TYPE" == "fedora" ]; then
            execute_with_progress "DNF Cache Clean" "sudo dnf clean all && sudo dnf makecache"
            return
        fi

        # 3. DEBIAN / UBUNTU / MX LINUX (APT)
        TARGET_URL=""
        case "$DISTRO" in
            debian)
                TARGET_URL="http://deb.debian.org/debian"
                ;;
            mx)
                # MX Linux gebruikt Debian Stable als basis
                TARGET_URL="http://deb.debian.org/debian"
                msg_info "MX Linux: We resetten alleen de Debian-basislaag."
                ;;
            linuxmint|ubuntu|pop|neon|zorin)
                TARGET_URL="http://archive.ubuntu.com/ubuntu"
                ;;
            kali)
                TARGET_URL="http://http.kali.org/kali"
                ;;
            *)
                msg_warn "Geen specifieke URL bekend voor $DISTRO. Sla over."
                return
                ;;
        esac

        echo -e "${BLUE}   Resetten naar hoofddomein: $TARGET_URL${NC}"

        # Functie om een bestand te repareren via sed regex
        fix_file() {
            local file="$1"
            if [ -f "$file" ]; then
                # Dit commando zoekt naar regels die beginnen met deb http...
                # En vervangt de domeinnaam voor de standaard $TARGET_URL
                # Het laat 'security' en 'updates' repo's met rust als ze een andere URL hebben
                
                if [[ "$DISTRO" == "mx" || "$DISTRO" == "debian" ]]; then
                    # Voor MX/Debian: Vervang ftp.xx.debian.org etc naar deb.debian.org
                    # We zijn voorzichtig: we vervangen alleen als het expliciet op een debian mirror lijkt
                    sudo sed -i "s|https\?://[a-z0-9.-]*debian.org/debian |$TARGET_URL |g" "$file" 2>/dev/null
                else
                    # Voor Ubuntu/Mint: Vervang landcodes (nl.archive...) naar archive.ubuntu.com
                    sudo sed -i "s|https\?://[a-z.]*archive.ubuntu.com/ubuntu |$TARGET_URL |g" "$file" 2>/dev/null
                fi
            fi
        }

        # Stap A: Fix hoofdbestand
        fix_file "/etc/apt/sources.list"

        # Stap B: Fix losse bestanden (Cruciaal voor MX Linux!)
        # MX slaat zijn debian lijst vaak op in /etc/apt/sources.list.d/debian.list
        for f in /etc/apt/sources.list.d/*.list; do
            fix_file "$f"
        done
        
        # Nieuwe stijl sources (Ubuntu 24.04 / Pop)
        if [ -f /etc/apt/sources.list.d/system.sources ]; then 
            sudo sed -i "s|URIs: http.*ubuntu.*|URIs: $TARGET_URL/|g" /etc/apt/sources.list.d/system.sources
        fi

        msg_ok "Mirrors gereset."
        
        # Probeer de update opnieuw
        task_update
    else 
        msg_warn "Herstel overgeslagen."
    fi
}

task_update() { 
    # Nala check
    if [ "$SYSTEM_TYPE" == "debian" ] && command -v nala &>/dev/null; then 
        echo -e "${BLUE}ℹ️  Gebruik Nala voor mirrors...${NC}"
    fi

    task_backup "AUTO"

    if [ "$SYSTEM_TYPE" == "debian" ]; then 
        sudo dpkg --configure -a &>/dev/null
    fi
    
    echo -e "${BLUE}🚀 Start Systeem Updates...${NC}"
    
    # Voer update uit
    eval "$CMD_UPDATE"
    
    # Als update faalt
    if [ $? -ne 0 ]; then 
        fix_broken_mirrors
    else
        msg_ok "Systeem is up-to-date."
    fi
    
    if command -v flatpak &>/dev/null; then 
        echo -e "${BLUE}📦 Start Flatpak Updates...${NC}"
        flatpak update -y --system
        flatpak uninstall --unused -y --system
    fi
}
