#!/usr/bin/env bash
set -euo pipefail

# checking root privilage.

if [[ $EUID -ne 0 ]]; then
    echo "[!] This script must be run as root. Please run with sudo or as root user."
    exit 1
fi

# changing nginx network port.

echo "[*] Configuring Nginx to listen on port 8088 instead of 80..."
sed -i 's/listen 80 default_server;/listen 8088 default_server;/ ' /etc/nginx/nginx.conf
sed -i 's/listen \[::\]:80 default_server;/listen \[::\]:8088 default_server;/ ' /etc/nginx/nginx.conf

#Checking and changing SElinux status.

echo "[*] Selinux status checking..."
if ! semanage port -l | grep -q "8088"; then 
    semanage port -a -t http_port_t -p tcp 8088
    echo "[*] Selinux port context for 8088 added."
else
    echo "[*] Selinux port context for 8088 already exists."
fi


echo "[*] Systemd sandbox configuration checking..."
mkdir -p /etc/systemd/system/nginx.service.d

cat << 'EOF' > /etc/systemd/system/nginx.service.d/override.conf
[Service]
# Uses 'strict' to instead of 'full' to mount the entire filesystem (including /var) as read-only.
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true
ReadWritePaths=/var/log/nginx /var/run /var/lib/nginx
EOF

systemctl daemon-reload


# Checking and changing firewall status and Audit configuration.

echo "[*] Firewall status checking..."
systemctl enable --now firewalld
firewall-cmd --add-port=8088/tcp --permanent
firewall-cmd --reload

echo "[*] Audit configuration checking..."
systemctl enable --now auditd
auditctl -a always,exit -F path=/etc/nginx/nginx.conf -F perm=wa -k nginx_config_change

echo "[*] Restarting Nginx service to apply changes..."


echo "[*] Nginx configuration completed successfully. Nginx is now listening on port 8088, SELinux context is updated, systemd sandbox is configured, firewall rules are set, and audit logging is enabled for nginx configuration changes."

# Checking security score and analyzing the configuration.

echo "[*] Checking Nginx security score and analyzing the configuration..."
systemctl restart nginx

echo "===================================="
echo "[*] Nginx Security Score and Configuration Analysis:"
systemd-analyze security nginx | tail -n 10
echo "===================================="

