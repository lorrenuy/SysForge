#!/bin/bash
optimize_gaming_tweaks() {
    msg_info "Gaming Tweaks..."
    if [ ! -f /etc/sysctl.d/99-gaming-sysforge.conf ]; then echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/99-gaming-sysforge.conf > /dev/null; sudo sysctl -p /etc/sysctl.d/99-gaming-sysforge.conf > /dev/null; msg_ok "Map Count Fix"; fi
    if ! grep -q "nofile 524288" /etc/security/limits.conf; then echo "* soft nofile 524288" | sudo tee -a /etc/security/limits.conf > /dev/null; echo "* hard nofile 524288" | sudo tee -a /etc/security/limits.conf > /dev/null; msg_ok "ULimit Fix"; fi
}
