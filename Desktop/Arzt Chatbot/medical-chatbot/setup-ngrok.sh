#!/bin/bash

# Komplettes Setup-Script für ngrok mit automatischer CORS-Konfiguration

cd "$(dirname "$0")"

echo "🚀 Ngrok Setup für Medical Chatbot"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob Container laufen
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Container laufen nicht. Starte zuerst:"
    echo "   docker compose up -d"
    exit 1
fi

# Stoppe laufende ngrok-Instanzen
echo "🛑 Stoppe laufende ngrok-Instanzen..."
pkill ngrok 2>/dev/null
sleep 2

echo ""
echo "📡 Starte ngrok Tunnels..."
echo ""

# Starte beide Tunnels mit Config-Datei
echo "1️⃣  Starte ngrok mit Config (Frontend + Backend)..."
ngrok start --all --config=ngrok.yml > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!

echo ""
echo "⏳ Warte auf ngrok Start..."
sleep 8

# Hole URLs von ngrok API (beide Tunnels auf Port 4040)
echo "🔍 Hole Tunnel URLs..."
TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

if [ -z "$TUNNELS_JSON" ]; then
    echo "❌ Konnte ngrok API nicht erreichen. Warte noch 5 Sekunden..."
    sleep 5
    TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
fi

# Extrahiere URLs
FRONTEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        config = tunnel.get('config', {})
        addr = str(config.get('addr', ''))
        if '3000' in addr:
            print(tunnel.get('public_url', ''))
            break
except Exception as e:
    pass
")

BACKEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        config = tunnel.get('config', {})
        addr = str(config.get('addr', ''))
        if '8000' in addr:
            print(tunnel.get('public_url', ''))
            break
except Exception as e:
    pass
")

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
    echo "❌ Konnte URLs nicht abrufen. Prüfe:"
    echo "   Frontend: http://localhost:4040"
    echo "   Backend: http://localhost:4041"
    exit 1
fi

echo ""
echo "✅ URLs erhalten:"
echo "   Frontend: $FRONTEND_URL"
echo "   Backend: $BACKEND_URL"
echo ""

# Backup docker-compose.yml
cp docker-compose.yml docker-compose.yml.bak

# Aktualisiere docker-compose.yml
echo "🔧 Aktualisiere Konfiguration..."

# Aktualisiere Frontend Backend-URL
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    # Aktualisiere CORS (füge Frontend-URL hinzu)
    sed -i '' "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
else
    sed -i "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    sed -i "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
fi

echo "🛑 Stoppe Container..."
docker compose down

echo "🔨 Baue Frontend mit neuer Backend-URL..."
docker compose up --build -d

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ FERTIG!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 FRONTEND URL (teilen!):"
echo "   $FRONTEND_URL"
echo ""
echo "🔧 BACKEND URL:"
echo "   $BACKEND_URL"
echo ""
echo "📋 Ngrok Web Interfaces:"
echo "   Frontend: http://localhost:4040"
echo "   Backend: http://localhost:4041"
echo ""
echo "⚠️  WICHTIG:"
echo "   - Ngrok muss laufen (beide Prozesse im Hintergrund)"
echo "   - Bei Neustart von ngrok: Führe dieses Script erneut aus"
echo "   - Zum Stoppen: pkill ngrok"
echo ""
echo "════════════════════════════════════════════════════════════"

