#!/bin/bash

# Schnelles VPS-Setup-Skript
# Führe dieses Skript auf dem VPS aus (nicht lokal!)

set -e

echo "🚀 Medical Chatbot - VPS Quick Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte als root ausführen: sudo $0"
    exit 1
fi

echo "📦 Schritt 1: System aktualisieren..."
apt update && apt upgrade -y

echo ""
echo "🐳 Schritt 2: Docker installieren..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "   Docker ist bereits installiert"
fi

echo ""
echo "📦 Schritt 3: Docker Compose installieren..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    apt install -y docker-compose-plugin
else
    echo "   Docker Compose ist bereits installiert"
fi

echo ""
echo "🔥 Schritt 4: Firewall einrichten..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

echo ""
echo "📁 Schritt 5: App-Verzeichnis erstellen..."
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

echo ""
echo "📥 Schritt 6: Repository klonen..."
if [ ! -d "medical-chatbot" ]; then
    if [ -d ".git" ]; then
        echo "   Repository bereits vorhanden, aktualisiere..."
        git pull
    else
        echo "   Klone Repository..."
        git clone https://github.com/YoussefHalitou/Dr_Carsten.git .
    fi
else
    echo "   App-Verzeichnis bereits vorhanden"
fi

cd medical-chatbot

echo ""
echo "⚙️  Schritt 7: .env Datei prüfen..."
if [ ! -f ".env" ]; then
    echo "⚠️  .env Datei nicht gefunden!"
    echo ""
    echo "   Erstelle eine .env Datei mit:"
    echo "   OPENAI_API_KEY=dein-key"
    echo "   API_KEY=dein-api-key"
    echo ""
    read -p "   Möchtest du die .env Datei jetzt erstellen? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        nano .env
    else
        echo "   Bitte erstelle die .env Datei manuell: nano .env"
    fi
else
    echo "   ✅ .env Datei vorhanden"
fi

echo ""
echo "🌐 Schritt 8: Nginx installieren..."
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
else
    echo "   Nginx ist bereits installiert"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Setup abgeschlossen!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Nächste Schritte:"
echo ""
echo "1. .env Datei prüfen/erstellen:"
echo "   cd /opt/medical-chatbot/medical-chatbot"
echo "   nano .env"
echo ""
echo "2. Nginx konfigurieren:"
echo "   nano /etc/nginx/sites-available/medical-chatbot"
echo "   (Siehe HOSTING-GUIDE.md für Konfiguration)"
echo ""
echo "3. App starten:"
echo "   cd /opt/medical-chatbot/medical-chatbot"
echo "   docker compose up -d --build"
echo ""
echo "4. Nginx aktivieren:"
echo "   ln -s /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/"
echo "   nginx -t"
echo "   systemctl restart nginx"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

