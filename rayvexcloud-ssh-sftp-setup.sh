#!/bin/bash
# ==========================================
# RayvexCloud Premium MOTD Installer (v3 PRO)
# FULL CLEAN + ONLY CUSTOM MOTD
# ==========================================

set -e

echo "🔧 Installing RayvexCloud Premium MOTD..."

# ================================
# ROOT CHECK
# ================================
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root."
    echo "Example: sudo bash install-rayvexcloud-motd.sh"
    exit 1
fi

# ================================
# REMOVE ALL OLD MOTD SYSTEM
# ================================
echo "🧹 Removing old MOTD completely..."

chmod -x /etc/update-motd.d/* 2>/dev/null || true

rm -f /etc/motd
rm -f /var/run/motd
rm -f /run/motd.dynamic

# Disable motd-news
if [ -f /etc/default/motd-news ]; then
    sed -i 's/ENABLED=1/ENABLED=0/g' /etc/default/motd-news
fi

# ================================
# FORCE ONLY OUR MOTD (PAM FIX)
# ================================
echo "⚙ Configuring PAM..."

cp /etc/pam.d/sshd /etc/pam.d/sshd.rayvexcloud.bak 2>/dev/null || true
cp /etc/pam.d/login /etc/pam.d/login.rayvexcloud.bak 2>/dev/null || true

# Remove old MOTD PAM entries
sed -i '/pam_motd.so/d' /etc/pam.d/sshd 2>/dev/null || true
sed -i '/pam_motd.so/d' /etc/pam.d/login 2>/dev/null || true

# Remove an older RayvexCloud pam_exec entry if this script was run before
sed -i '\#pam_exec.so stdout /etc/update-motd.d/00-rayvexcloud#d' /etc/pam.d/sshd 2>/dev/null || true
sed -i '\#pam_exec.so stdout /etc/update-motd.d/00-rayvexcloud#d' /etc/pam.d/login 2>/dev/null || true

# Add ONLY our MOTD
echo "session optional pam_exec.so stdout /etc/update-motd.d/00-rayvexcloud" >> /etc/pam.d/sshd
echo "session optional pam_exec.so stdout /etc/update-motd.d/00-rayvexcloud" >> /etc/pam.d/login

# ================================
# CREATE RAYVEXCLOUD MOTD
# ================================
echo "✨ Creating RayvexCloud MOTD..."

cat << 'EOF' > /etc/update-motd.d/00-rayvexcloud
#!/bin/bash

# ===== Colors =====
GREEN="\e[38;5;82m"
CYAN="\e[38;5;51m"
BLUE="\e[38;5;39m"
MAGENTA="\e[38;5;213m"
YELLOW="\e[38;5;220m"
GRAY="\e[38;5;245m"
RESET="\e[0m"

# ===== System Info =====
HOSTNAME=$(hostname)
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
UPTIME=$(uptime -p | sed 's/up //')

CPU=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
[ -z "$CPU" ] && CPU="N/A"

MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')

if [ -n "$MEM_TOTAL" ] && [ "$MEM_TOTAL" -gt 0 ]; then
    MEM_PERC=$((MEM_USED * 100 / MEM_TOTAL))
else
    MEM_PERC=0
fi

DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="N/A"

USERS=$(who 2>/dev/null | wc -l)
PROCS=$(ps -e --no-headers 2>/dev/null | wc -l)

echo ""

# ===== LOGO =====
echo -e "${MAGENTA}"
cat << "LOGO"
██████╗  █████╗ ██╗   ██╗██╗   ██╗███████╗██╗  ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝██║   ██║██╔════╝╚██╗██╔╝
██████╔╝███████║ ╚████╔╝ ██║   ██║█████╗   ╚███╔╝
██╔══██╗██╔══██║  ╚██╔╝  ╚██╗ ██╔╝██╔══╝   ██╔██╗
██║  ██║██║  ██║   ██║    ╚████╔╝ ███████╗██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝     ╚═══╝  ╚══════╝╚═╝  ╚═╝
LOGO
echo -e "${RESET}"

# ===== HEADER =====
echo -e "${GREEN}🚀 Welcome to RayvexCloud Datacenter${RESET}"
echo -e "${BLUE}High Performance • Secure • Reliable Infrastructure${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ===== STATS =====
printf "${CYAN}%-18s${RESET} %s\n" "Hostname:" "$HOSTNAME"
printf "${CYAN}%-18s${RESET} %s\n" "OS:" "$OS"
printf "${CYAN}%-18s${RESET} %s\n" "Kernel:" "$KERNEL"
printf "${CYAN}%-18s${RESET} %s\n" "Uptime:" "$UPTIME"
printf "${CYAN}%-18s${RESET} %s\n" "CPU Usage:" "$CPU"
printf "${CYAN}%-18s${RESET} %sMB / %sMB (${YELLOW}%s%%${RESET})\n" "Memory:" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERC"
printf "${CYAN}%-18s${RESET} %s\n" "Disk:" "$DISK"
printf "${CYAN}%-18s${RESET} %s\n" "Processes:" "$PROCS"
printf "${CYAN}%-18s${RESET} %s\n" "Users:" "$USERS"
printf "${CYAN}%-18s${RESET} %s\n" "IP:" "$IP"

echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ===== FOOTER =====
echo -e "${GREEN}Support:${RESET}  support@rayvex.in"
echo -e "${GREEN}Discord:${RESET}  https://discord.gg/yFUHdUmBm"
echo -e "${GREEN}Website:${RESET}  https://rayvex.in"
echo -e "${MAGENTA}RayvexCloud — You Meet The Legacy ⚡${RESET}"
echo ""
EOF

chmod +x /etc/update-motd.d/00-rayvexcloud

# ================================
# VALIDATE MOTD SCRIPT
# ================================
echo "🧪 Testing MOTD..."

bash -n /etc/update-motd.d/00-rayvexcloud
/etc/update-motd.d/00-rayvexcloud

# ================================
# RESTART SSH
# ================================
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true

echo ""
echo "✅ RayvexCloud MOTD Installed Successfully!"
echo "🚫 Default MOTD disabled"
echo "🔥 Only RayvexCloud MOTD is enabled"
echo "➡ Reconnect SSH to see the MOTD"
