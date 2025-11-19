#!/bin/bash

# Script zum Einrichten eines VPS für die Medical Chatbot App
# Verwendung: Auf dem VPS ausführen

set -e

echo "🚀 VPS Setup Script für Medical Chatbot"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Bitte als root ausführen: sudo ./setup-vps.sh"
    exit 1
fi

echo "📦 Schritt 1: System-Updates..."
echo ""

apt update
apt upgrade -y

echo ""
echo "🔧 Schritt 2: Basis-Tools installieren..."
echo ""

apt install -y curl wget git vim ufw

echo ""
echo "🔥 Schritt 3: Firewall einrichten..."
echo ""

ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

echo ""
echo "🐳 Schritt 4: Docker installieren..."
echo ""

if ! command -v docker &> /dev/null; then
    echo "   Docker nicht gefunden. Installiere Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl start docker
    systemctl enable docker
else
    echo "   Docker bereits installiert."
fi

echo ""
echo "📦 Schritt 5: Docker Compose installieren..."
echo ""

if ! command -v docker compose &> /dev/null; then
    echo "   Docker Compose nicht gefunden. Installiere Docker Compose..."
    apt install -y docker-compose-plugin
else
    echo "   Docker Compose bereits installiert."
fi

echo ""
echo "🌐 Schritt 6: Nginx installieren..."
echo ""

if ! command -v nginx &> /dev/null; then
    echo "   Nginx nicht gefunden. Installiere Nginx..."
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
else
    echo "   Nginx bereits installiert."
fi

echo ""
echo "🔒 Schritt 7: Certbot installieren..."
echo ""

if ! command -v certbot &> /dev/null; then
    echo "   Certbot nicht gefunden. Installiere Certbot..."
    apt install -y certbot python3-certbot-nginx
else
    echo "   Certbot bereits installiert."
fi

echo ""
echo "✅ Schritt 8: Verzeichnis erstellen..."
echo ""

mkdir -p /opt/medical-chatbot
chmod 755 /opt/medical-chatbot

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ VPS SETUP ABGESCHLOSSEN!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Installierte Komponenten:"
echo "   ✅ Docker: $(docker --version 2>/dev/null || echo 'Nicht installiert')"
echo "   ✅ Docker Compose: $(docker compose version 2>/dev/null || echo 'Nicht installiert')"
echo "   ✅ Nginx: $(nginx -v 2>&1 | head -1 || echo 'Nicht installiert')"
echo "   ✅ Certbot: $(certbot --version 2>/dev/null || echo 'Nicht installiert')"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. App deployen: ./deploy-to-vps.sh user@vps-ip"
echo "   2. Oder manuell: git clone und docker compose up -d"
echo "   3. Nginx konfigurieren (siehe VPS-DEPLOYMENT.md)"
echo "   4. SSL-Zertifikat erstellen: certbot --nginx -d deine-domain.com"
echo ""
echo "════════════════════════════════════════════════════════════"

