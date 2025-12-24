#!/bin/bash
menu_advanced_tools() {
    while true; do
        draw_header; echo -e "${RED}--- ADVANCED ---${NC}"; echo "   1) 🚑 Repair Desktop"; echo "   2) ☁️  Cloud Config"; echo "   3) 🔗 Mount Cloud"; echo "   4) 🔙 Restore Cloud"; echo "   5) ☢️  WIPE DISK"; echo ""; echo "   0) 🔙 Terug"; read -p "   : " A
        case $A in 1) repair_desktop ;; 2) setup_rclone_simplified ;; 3) task_mount_cloud ;; 4) restore_from_cloud ;; 5) nuclear_wipe ;; 0) return ;; esac
    done
}
repair_desktop() {
    read -p "   Type 'RESET' to confirm: " C; if [ "$C" == "RESET" ]; then
        msg_info "Repairing..."; if [[ "$CURRENT_DE" == *"Pop"* ]]; then execute_with_progress "Reinstall" "$CMD_INSTALL --reinstall pop-desktop gnome-shell"; dconf reset -f /org/gnome/; dconf reset -f /com/system76/; fi
        sudo reboot
    fi
}
uninstall_sysforge() { rm -rf "$CONFIG_DIR" "$LOG_DIR" "$DOCS_DIR/SysForge.sh"; echo "Verwijderd."; exit 0; }
nuclear_wipe() {
    read -p "   Type 'VERNIETIG': " C1; if [ "$C1" != "VERNIETIG" ]; then return; fi
    read -p "   Type 'JA IK WIL DATA VERLIEZEN': " C2; if [ "$C2" != "JA IK WIL DATA VERLIEZEN" ]; then return; fi
    read -p "   Type hostname ($PC_NAME): " C3; if [ "$C3" != "$PC_NAME" ]; then return; fi
    RD=$(lsblk -ndo pkname $(findmnt -n / | awk '{print $2}')); sudo shred -v -n 1 -z "/dev/$RD"; sudo poweroff
}
