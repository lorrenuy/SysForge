#!/bin/bash
setup_rclone_simplified() {
    echo "1) GDrive 2) OneDrive"; read -p "   : " CC; case $CC in 1) R="gdrive"; rclone config create "$R" drive config_is_local true ;; 2) R="onedrive"; rclone config create "$R" onedrive config_is_local true ;; esac
    if rclone about "$R:" >/dev/null 2>&1; then msg_ok "OK"; RCLONE_REMOTE="$R"; else msg_err "Fail"; fi
}
task_mount_cloud() {
    if [ -z "$RCLONE_REMOTE" ]; then msg_err "Geen config"; return; fi
    CD="$REAL_HOME/CloudDrive"; if [ "$SYSTEM_TYPE" == "debian" ]; then execute_with_progress "Fuse3" "$CMD_INSTALL fuse3"; fi
    sudo -u "$REAL_USER" mkdir -p "$CD"; SD="$REAL_HOME/.config/systemd/user"; sudo -u "$REAL_USER" mkdir -p "$SD"
    cat > "$SD/rclone-mount.service" <<EOF
[Unit]
Description=Rclone Mount
After=network-online.target
[Service]
Type=notify
ExecStart=/usr/bin/rclone mount $RCLONE_REMOTE: $CD --vfs-cache-mode writes --vfs-cache-max-size 5G --allow-other
ExecStop=/bin/fusermount -u $CD
Restart=always
RestartSec=10
[Install]
WantedBy=default.target
EOF
    chown "$REAL_USER":"$REAL_USER" "$SD/rclone-mount.service"; sudo -u "$REAL_USER" systemctl --user daemon-reload; sudo -u "$REAL_USER" systemctl --user enable --now rclone-mount.service
    msg_ok "Mounted: ~/CloudDrive"; read -p "   Enter..."
}
task_backup() { 
    if ! check_disk_space; then return; fi; if ! command -v timeshift &>/dev/null; then execute_with_progress "Timeshift" "$CMD_INSTALL timeshift"; fi
    execute_with_progress "Snapshot" "sudo timeshift --create --comments 'SysForge' --tags O"; if [ "$USE_CLOUD_UPLOAD" = true ]; then upload_to_gdrive; fi
}
upload_to_gdrive() {
    if ! command -v rclone &>/dev/null || [ -z "$RCLONE_REMOTE" ]; then return; fi
    LST=$(sudo timeshift --list | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}' | tail -n 1)
    if [ -n "$LST" ]; then execute_with_progress "Upload Cloud" "sudo tar -cf - \"/timeshift/snapshots/$LST\" | gzip | rclone rcat \"$RCLONE_REMOTE:$RCLONE_FOLDER/Backup_${PC_NAME}_${LST}.tar.gz\""; fi
}
