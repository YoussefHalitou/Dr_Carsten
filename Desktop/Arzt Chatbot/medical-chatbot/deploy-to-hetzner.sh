#!/bin/bash

# Spezielles Deployment-Script für Hetzner VPS
# Verwendung: ./deploy-to-hetzner.sh

set -e

VPS_IP="37.27.12.97"
VPS_USER="root"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Hetzner VPS Deployment"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "VPS IP: $VPS_IP"
echo "User: $VPS_USER"
echo ""

# Prüfe SSH-Verbindung
echo "🔐 Schritt 1: SSH-Verbindung testen..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "echo 'OK'" > /dev/null 2>&1; then
    echo "✅ SSH-Verbindung erfolgreich!"
else
    echo "❌ SSH-Verbindung fehlgeschlagen!"
    echo ""
    echo "💡 Mögliche Lösungen:"
    echo "   1. Prüfe ob der VPS läuft"
    echo "   2. Prüfe SSH-Zugriff (Passwort oder Key)"
    echo "   3. Teste manuell: ssh $VPS_USER@$VPS_IP"
    exit 1
fi

echo ""
echo "📦 Schritt 2: VPS Setup..."
echo ""

# Prüfe ob .env existiert
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "⚠️  .env Datei nicht gefunden!"
    echo "   Erstelle eine .env Datei mit den notwendigen Variablen."
    read -p "Möchtest du fortfahren ohne .env? (j/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        exit 1
    fi
fi

# VPS Setup Script hochladen und ausführen
echo "   Lade setup-vps.sh hoch..."
scp "$SCRIPT_DIR/setup-vps.sh" "$VPS_USER@$VPS_IP:/tmp/setup-vps.sh"

echo "   Führe VPS Setup aus..."
ssh "$VPS_USER@$VPS_IP" << 'ENDSSH'
set -e
chmod +x /tmp/setup-vps.sh
sudo /tmp/setup-vps.sh
rm /tmp/setup-vps.sh
ENDSSH

echo ""
echo "📤 Schritt 3: App deployen..."
echo ""

# Erstelle temporäres Verzeichnis
TEMP_DIR=$(mktemp -d)
echo "   Erstelle App-Archiv..."

cd "$SCRIPT_DIR"
tar -czf "$TEMP_DIR/medical-chatbot.tar.gz" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    --exclude='*.log' \
    --exclude='dist' \
    --exclude='.DS_Store' \
    .

echo "   Lade App hoch..."
scp "$TEMP_DIR/medical-chatbot.tar.gz" "$VPS_USER@$VPS_IP:/tmp/"

if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "   Lade .env hoch..."
    scp "$SCRIPT_DIR/.env" "$VPS_USER@$VPS_IP:/tmp/.env"
fi

echo ""
echo "🔧 Schritt 4: App auf VPS einrichten..."
echo ""

ssh "$VPS_USER@$VPS_IP" << 'ENDSSH'
set -e

echo "   Erstelle Verzeichnis..."
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

echo "   Entpacke App..."
tar -xzf /tmp/medical-chatbot.tar.gz
rm /tmp/medical-chatbot.tar.gz

if [ -f /tmp/.env ]; then
    echo "   Kopiere .env..."
    cp /tmp/.env /opt/medical-chatbot/.env
    rm /tmp/.env
    chmod 600 /opt/medical-chatbot/.env
else
    echo "   ⚠️  .env nicht gefunden. Erstelle Beispiel .env..."
    cat > /opt/medical-chatbot/.env << 'ENVEOF'
OPENAI_API_KEY=dein-openai-api-key-hier
API_KEY=dein-starker-api-key-hier
CORS_ORIGINS=http://localhost:3000
ENFORCE_HTTPS=true
DEBUG=false
SQLALCHEMY_ECHO=false
ENVEOF
    echo "   ⚠️  Bitte bearbeite /opt/medical-chatbot/.env mit deinen Werten!"
fi

echo "   Baue und starte Container..."
cd /opt/medical-chatbot
docker compose down 2>/dev/null || true
docker compose up -d --build

echo ""
echo "   ✅ Deployment abgeschlossen!"
echo ""
echo "   Status:"
docker compose ps

echo ""
echo "   Logs (letzte 20 Zeilen):"
docker compose logs --tail=20

ENDSSH

# Aufräumen
rm -rf "$TEMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT ABGESCHLOSSEN!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Deine App ist jetzt erreichbar unter:"
echo "   http://37.27.12.97:3000 (Frontend)"
echo "   http://37.27.12.97:8000 (Backend API)"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. Prüfe Status: ssh $VPS_USER@$VPS_IP 'cd /opt/medical-chatbot && docker compose ps'"
echo "   2. Siehe Logs: ssh $VPS_USER@$VPS_IP 'cd /opt/medical-chatbot && docker compose logs -f'"
echo "   3. Bearbeite .env: ssh $VPS_USER@$VPS_IP 'nano /opt/medical-chatbot/.env'"
echo "   4. Richte Nginx ein (optional, siehe VPS-DEPLOYMENT.md)"
echo "   5. Richte Domain ein (optional)"
echo ""
echo "🔒 WICHTIG:"
echo "   - Bearbeite /opt/medical-chatbot/.env mit deinen API-Keys!"
echo "   - Starte Container neu: docker compose restart"
echo ""
echo "════════════════════════════════════════════════════════════"

