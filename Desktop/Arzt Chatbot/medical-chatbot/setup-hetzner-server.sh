#!/bin/bash

# Automatisches Setup-Skript für Hetzner Server
# Führe dieses Skript auf dem neu erstellten Hetzner Server aus

set -e

echo "🚀 Medical Chatbot - Hetzner Server Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte als root ausführen: sudo $0"
    exit 1
fi

# System aktualisieren
echo "📦 Schritt 1/8: System aktualisieren..."
apt update && apt upgrade -y

# Basis-Tools installieren
echo ""
echo "📦 Schritt 2/8: Basis-Tools installieren..."
apt install -y curl wget git vim ufw

# Docker installieren
echo ""
echo "🐳 Schritt 3/8: Docker installieren..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo "   ✅ Docker installiert"
else
    echo "   ✅ Docker bereits installiert"
fi

# Docker Compose installieren
echo ""
echo "📦 Schritt 4/8: Docker Compose installieren..."
if ! docker compose version &> /dev/null; then
    apt install -y docker-compose-plugin
    echo "   ✅ Docker Compose installiert"
else
    echo "   ✅ Docker Compose bereits installiert"
fi

# Firewall einrichten
echo ""
echo "🔥 Schritt 5/8: Firewall einrichten..."
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable
echo "   ✅ Firewall konfiguriert"

# App-Verzeichnis erstellen
echo ""
echo "📁 Schritt 6/8: App-Verzeichnis erstellen..."
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

# Repository klonen
echo ""
echo "📥 Schritt 7/8: Repository klonen..."
if [ ! -d "medical-chatbot" ]; then
    if [ -d ".git" ]; then
        echo "   Repository bereits vorhanden, aktualisiere..."
        git pull
    else
        echo "   Klone Repository von GitHub..."
        git clone https://github.com/YoussefHalitou/Dr_Carsten.git .
    fi
    echo "   ✅ Repository geklont"
else
    echo "   ✅ App-Verzeichnis bereits vorhanden"
fi

cd medical-chatbot

# .env Datei prüfen
echo ""
echo "⚙️  Schritt 8/8: .env Datei prüfen..."
if [ ! -f ".env" ]; then
    echo "⚠️  .env Datei nicht gefunden!"
    echo ""
    echo "   Erstelle eine .env Datei mit:"
    echo "   OPENAI_API_KEY=dein-openai-api-key"
    echo "   API_KEY=dein-starker-api-key"
    echo ""
    read -p "   Möchtest du die .env Datei jetzt erstellen? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        cat > .env << 'EOF'
# OpenAI API Key
OPENAI_API_KEY=

# API Key für Authentifizierung
API_KEY=

# CORS Origins (wird automatisch angepasst)
CORS_ORIGINS=http://localhost:3000

# HTTPS Enforcement
ENFORCE_HTTPS=false

# Environment
ENVIRONMENT=production
EOF
        nano .env
    else
        echo "   Bitte erstelle die .env Datei manuell: nano .env"
    fi
else
    echo "   ✅ .env Datei vorhanden"
fi

# Nginx installieren
echo ""
echo "🌐 Nginx installieren..."
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "   ✅ Nginx installiert"
else
    echo "   ✅ Nginx bereits installiert"
fi

# Nginx-Konfiguration erstellen
echo ""
echo "⚙️  Nginx-Konfiguration erstellen..."
SERVER_IP=$(hostname -I | awk '{print $1}')

cat > /etc/nginx/sites-available/medical-chatbot << EOF
server {
    listen 80;
    server_name ${SERVER_IP};

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # WebSocket Support
    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Nginx-Konfiguration aktivieren
ln -sf /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Setup abgeschlossen!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Nächste Schritte:"
echo ""
echo "1. .env Datei mit deinen API-Keys füllen:"
echo "   cd /opt/medical-chatbot/medical-chatbot"
echo "   nano .env"
echo ""
echo "2. App starten:"
echo "   docker compose up -d --build"
echo ""
echo "3. Status prüfen:"
echo "   docker compose ps"
echo "   docker compose logs -f"
echo ""
echo "4. App testen:"
echo "   curl http://localhost:3000"
echo ""
echo "🌐 Deine App ist dann erreichbar unter:"
echo "   http://${SERVER_IP}"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

