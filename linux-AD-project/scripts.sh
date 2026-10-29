#!/bin/bash
set -euo pipefail

sudo dnf update -y
sudo dnf install -y nginx openssl firewalld

sudo systemctl enable --now firewalld nginx

sudo mkdir -p /etc/nginx/tls /var/www/



sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/tls/selfsigned.key \
  -out /etc/nginx/tls/selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=example.com"

sudo chmod 600 /etc/nginx/tls/selfsigned.key
sudo chmod 644 /etc/nginx/tls/selfsigned.crt

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

sudo nginx -t
sudo systemctl reload nginx
