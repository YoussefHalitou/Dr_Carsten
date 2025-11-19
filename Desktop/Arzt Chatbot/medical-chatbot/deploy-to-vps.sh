#!/bin/bash

# Script zum Deployment auf VPS
# Verwendung: ./deploy-to-vps.sh user@vps-ip

set -e

VPS_HOST="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$VPS_HOST" ]; then
    echo "❌ Verwendung: ./deploy-to-vps.sh user@vps-ip"
    echo "   Beispiel: ./deploy-to-vps.sh root@123.456.789.0"
    exit 1
fi

echo "🚀 VPS Deployment Script"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "VPS: $VPS_HOST"
echo ""

# Prüfe ob .env existiert
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "⚠️  .env Datei nicht gefunden!"
    echo "   Erstelle eine .env Datei mit den notwendigen Variablen."
    exit 1
fi

echo "📦 Schritt 1: Vorbereitung..."
echo ""

# Erstelle temporäres Verzeichnis
TEMP_DIR=$(mktemp -d)
echo "   Temporäres Verzeichnis: $TEMP_DIR"

# Kopiere App-Dateien
echo "   Kopiere App-Dateien..."
cd "$SCRIPT_DIR"
tar -czf "$TEMP_DIR/medical-chatbot.tar.gz" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    --exclude='*.log' \
    --exclude='dist' \
    .

echo ""
echo "📤 Schritt 2: Upload zu VPS..."
echo ""

# Upload zu VPS
scp "$TEMP_DIR/medical-chatbot.tar.gz" "$VPS_HOST:/tmp/"
scp "$SCRIPT_DIR/.env" "$VPS_HOST:/tmp/"

echo ""
echo "🔧 Schritt 3: Setup auf VPS..."
echo ""

# SSH-Commands auf VPS ausführen
ssh "$VPS_HOST" << 'ENDSSH'
set -e

echo "   Erstelle Verzeichnis..."
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

echo "   Entpacke App..."
tar -xzf /tmp/medical-chatbot.tar.gz
rm /tmp/medical-chatbot.tar.gz

echo "   Kopiere .env..."
cp /tmp/.env /opt/medical-chatbot/.env
rm /tmp/.env

echo "   Prüfe Docker..."
if ! command -v docker &> /dev/null; then
    echo "   Docker nicht gefunden. Installiere Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
fi

echo "   Prüfe Docker Compose..."
if ! command -v docker compose &> /dev/null; then
    echo "   Docker Compose nicht gefunden. Installiere Docker Compose..."
    apt update
    apt install -y docker-compose-plugin
fi

echo "   Baue und starte Container..."
docker compose down 2>/dev/null || true
docker compose up -d --build

echo ""
echo "   ✅ Deployment abgeschlossen!"
echo ""
echo "   Status:"
docker compose ps

echo ""
echo "   Logs:"
docker compose logs --tail=20

ENDSSH

# Aufräumen
rm -rf "$TEMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT ABGESCHLOSSEN!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. SSH zum VPS: ssh $VPS_HOST"
echo "   2. Prüfe Status: cd /opt/medical-chatbot && docker compose ps"
echo "   3. Siehe Logs: docker compose logs -f"
echo "   4. Richte Nginx ein (siehe VPS-DEPLOYMENT.md)"
echo "   5. Richte Domain ein (optional)"
echo ""
echo "════════════════════════════════════════════════════════════"

