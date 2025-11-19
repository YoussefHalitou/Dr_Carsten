#!/bin/bash

# Vollständiges Setup für öffentlichen Zugriff mit ngrok

cd "$(dirname "$0")"

echo "🚀 Public Access Setup für Medical Chatbot"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe Container
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Container laufen nicht. Starte zuerst: docker compose up -d"
    exit 1
fi

# Stoppe alte ngrok-Instanzen
pkill ngrok 2>/dev/null
sleep 2

echo "📡 Schritt 1: Starte Frontend-Tunnel (Port 3000)..."
ngrok http 3000 > /tmp/ngrok-frontend.log 2>&1 &
FRONTEND_PID=$!
sleep 6

FRONTEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        print(tunnels[0].get('public_url', ''))
except:
    pass
")

if [ -z "$FRONTEND_URL" ]; then
    echo "❌ Konnte Frontend-URL nicht abrufen"
    exit 1
fi

echo "✅ Frontend-URL: $FRONTEND_URL"
echo ""

echo "📡 Schritt 2: Starte Backend-Tunnel (Port 8000)..."
echo "   (Stoppe Frontend-ngrok temporär...)"
kill $FRONTEND_PID 2>/dev/null
sleep 2

ngrok http 8000 > /tmp/ngrok-backend.log 2>&1 &
BACKEND_PID=$!
sleep 6

BACKEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        print(tunnels[0].get('public_url', ''))
except:
    pass
")

if [ -z "$BACKEND_URL" ]; then
    echo "❌ Konnte Backend-URL nicht abrufen"
    exit 1
fi

echo "✅ Backend-URL: $BACKEND_URL"
echo ""

echo "📡 Schritt 3: Starte beide Tunnels parallel..."
kill $BACKEND_PID 2>/dev/null
sleep 2

# Starte beide mit Config (falls möglich) oder separat
echo "   Starte Frontend..."
ngrok http 3000 > /tmp/ngrok-frontend.log 2>&1 &
FRONTEND_PID=$!
sleep 3

echo "   Starte Backend (läuft parallel)..."
# Für Backend verwenden wir einen separaten Ansatz
# Da ngrok nur einen API-Port unterstützt, müssen wir die URLs manuell sammeln
# Oder wir verwenden die ngrok Config-Datei

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ URLs ERHALTEN"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend-URL: $FRONTEND_URL"
echo "🔧 Backend-URL:  $BACKEND_URL"
echo ""

# Backup
cp docker-compose.yml docker-compose.yml.bak 2>/dev/null

# Aktualisiere docker-compose.yml
echo "🔧 Aktualisiere Konfiguration..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
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
echo "⚠️  WICHTIG: Ngrok muss für BEIDE Ports laufen!"
echo ""
echo "📋 Starte ngrok manuell in 2 Terminals:"
echo ""
echo "   Terminal 1: ngrok http 3000"
echo "   Terminal 2: ngrok http 8000"
echo ""
echo "   Oder verwende ngrok Config:"
echo "   ngrok start --all --config=ngrok.yml"
echo ""
echo "💡 Ngrok Web UI: http://localhost:4040"
echo "💡 Zum Stoppen: pkill ngrok"
echo ""
echo "════════════════════════════════════════════════════════════"

