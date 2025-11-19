#!/bin/bash

# Deployment-Skript für bestehenden Hetzner Server
# Verwendung: ./deploy-to-existing-hetzner.sh root@DEINE_IP_ADRESSE

set -e

VPS_HOST="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$VPS_HOST" ]; then
    echo "❌ Verwendung: ./deploy-to-existing-hetzner.sh root@DEINE_IP_ADRESSE"
    echo ""
    echo "   Beispiel:"
    echo "   ./deploy-to-existing-hetzner.sh root@123.456.789.0"
    echo ""
    echo "   💡 Die IP-Adresse findest du in der Hetzner Cloud Console"
    echo "      unter 'Primary IPs' bei deinem Server"
    exit 1
fi

echo "🚀 Medical Chatbot - Deployment zu Hetzner Server"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Server: $VPS_HOST"
echo ""

# Prüfe SSH-Verbindung
echo "🔍 Prüfe SSH-Verbindung..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$VPS_HOST" exit 2>/dev/null; then
    echo "❌ Kann nicht mit Server verbinden!"
    echo ""
    echo "   Bitte prüfe:"
    echo "   1. IP-Adresse ist korrekt"
    echo "   2. SSH-Key ist auf dem Server hinterlegt"
    echo "   3. Server ist erreichbar"
    echo ""
    echo "   Teste manuell: ssh $VPS_HOST"
    exit 1
fi

echo "✅ SSH-Verbindung erfolgreich"
echo ""

# Prüfe ob .env existiert
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "⚠️  .env Datei nicht gefunden!"
    echo ""
    echo "   Erstelle eine .env Datei mit:"
    echo "   OPENAI_API_KEY=dein-key"
    echo "   API_KEY=dein-api-key"
    echo ""
    read -p "   Möchtest du die .env Datei jetzt erstellen? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        cat > "$SCRIPT_DIR/.env" << 'EOF'
OPENAI_API_KEY=
API_KEY=
CORS_ORIGINS=http://localhost:3000
ENFORCE_HTTPS=false
ENVIRONMENT=production
EOF
        echo "   Öffne .env Datei zum Bearbeiten..."
        ${EDITOR:-nano} "$SCRIPT_DIR/.env"
    else
        echo "   Bitte erstelle die .env Datei manuell: nano .env"
        exit 1
    fi
fi

echo "📦 Schritt 1: Setup-Skript auf Server hochladen..."
scp "$SCRIPT_DIR/setup-hetzner-server.sh" "$VPS_HOST:/root/setup.sh"

echo ""
echo "🚀 Schritt 2: Setup auf Server ausführen..."
ssh "$VPS_HOST" << 'ENDSSH'
    chmod +x /root/setup.sh
    /root/setup.sh
ENDSSH

echo ""
echo "📋 Schritt 3: .env Datei auf Server kopieren..."
scp "$SCRIPT_DIR/.env" "$VPS_HOST:/opt/medical-chatbot/medical-chatbot/.env"

echo ""
echo "🔧 Schritt 4: CORS_ORIGINS mit Server-IP aktualisieren..."
SERVER_IP=$(ssh "$VPS_HOST" "hostname -I | awk '{print \$1}'")
ssh "$VPS_HOST" << ENDSSH
    cd /opt/medical-chatbot/medical-chatbot
    sed -i "s|CORS_ORIGINS=.*|CORS_ORIGINS=http://localhost:3000,http://${SERVER_IP}|g" .env
    sed -i "s|VITE_BACKEND_URL=.*|VITE_BACKEND_URL=http://${SERVER_IP}:8000|g" docker-compose.yml 2>/dev/null || true
ENDSSH

echo ""
echo "🐳 Schritt 5: Docker Container starten..."
ssh "$VPS_HOST" << 'ENDSSH'
    cd /opt/medical-chatbot/medical-chatbot
    docker compose up -d --build
ENDSSH

echo ""
echo "⏳ Warte auf Container-Start (10 Sekunden)..."
sleep 10

echo ""
echo "🔍 Schritt 6: Status prüfen..."
ssh "$VPS_HOST" << 'ENDSSH'
    cd /opt/medical-chatbot/medical-chatbot
    echo ""
    echo "Container-Status:"
    docker compose ps
    echo ""
    echo "Backend Health-Check:"
    curl -s http://localhost:8000/health || echo "Backend noch nicht bereit"
    echo ""
ENDSSH

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Deployment abgeschlossen!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Deine App ist jetzt erreichbar unter:"
echo "   http://${SERVER_IP}"
echo ""
echo "📋 Nützliche Befehle:"
echo ""
echo "   # Logs ansehen"
echo "   ssh $VPS_HOST 'cd /opt/medical-chatbot/medical-chatbot && docker compose logs -f'"
echo ""
echo "   # Status prüfen"
echo "   ssh $VPS_HOST 'cd /opt/medical-chatbot/medical-chatbot && docker compose ps'"
echo ""
echo "   # App neu starten"
echo "   ssh $VPS_HOST 'cd /opt/medical-chatbot/medical-chatbot && docker compose restart'"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

