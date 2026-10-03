#!/bin/bash
# ==========================================
# RayvexCloud SSH + SFTP Setup
# MOTD UNTOUCHED
# ==========================================

set -e

echo "=========================================="
echo " RayvexCloud SSH + SFTP Setup"
echo " MOTD will NOT be modified"
echo "=========================================="
echo ""

# Must run as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root."
    echo "Example: sudo bash $0"
    exit 1
fi

# ================================
# INSTALL OPENSSH SERVER
# ================================
echo "📦 Installing OpenSSH Server..."

apt update
apt install -y openssh-server

# ================================
# CONFIGURE SSH + SFTP
# ================================
echo "⚙️ Configuring SSH + SFTP..."

# Backup SSH config once
if [ ! -f /etc/ssh/sshd_config.rayvexcloud.bak ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.rayvexcloud.bak
fi

# Remove old/conflicting settings so this script is safe to re-run
sed -i \
    -e '/^[[:space:]]*PasswordAuthentication[[:space:]]/d' \
    -e '/^[[:space:]]*PermitRootLogin[[:space:]]/d' \
    -e '/^[[:space:]]*PubkeyAuthentication[[:space:]]/d' \
    -e '/^[[:space:]]*KbdInteractiveAuthentication[[:space:]]/d' \
    -e '/^[[:space:]]*ChallengeResponseAuthentication[[:space:]]/d' \
    -e '/^[[:space:]]*UsePAM[[:space:]]/d' \
    -e '/^[[:space:]]*Subsystem[[:space:]]\+sftp[[:space:]]/d' \
    /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config <<'EOF'

# ==========================================
# RayvexCloud SSH + SFTP Configuration
# ==========================================
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# ================================
# VALIDATE SSH CONFIG
# ================================
echo "🔍 Validating SSH configuration..."

sshd -t

# ================================
# ENABLE + RESTART SSH
# ================================
echo "🚀 Enabling and restarting SSH..."

systemctl enable ssh
systemctl restart ssh

# ================================
# ROOT PASSWORD
# ================================
echo ""
echo "🔐 Set the root password now:"
passwd root

# ================================
# FINAL STATUS
# ================================
echo ""
echo "=========================================="
echo "✅ SSH + SFTP configured successfully."
echo "=========================================="
echo "SSH:                  Enabled"
echo "SFTP:                 Enabled"
echo "Root Login:           Enabled"
echo "Password Login:       Enabled"
echo "Public Key Login:     Disabled"
echo "MOTD:                 UNTOUCHED"
echo ""
echo "🔄 Reconnect using SSH to test access."
echo ""
