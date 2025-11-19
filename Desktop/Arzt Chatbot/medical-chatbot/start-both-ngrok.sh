#!/bin/bash

# Script zum Starten beider ngrok-Tunnels und Aktualisieren der Konfiguration

cd "$(dirname "$0")"

echo "🚀 Starte ngrok für Frontend und Backend..."
echo ""

# Stoppe alte ngrok-Instanzen
pkill ngrok 2>/dev/null
sleep 2

# Schritt 1: Frontend-URL holen
echo "📡 Schritt 1: Hole Frontend-URL..."
ngrok http 3000 > /tmp/ngrok-frontend-temp.log 2>&1 &
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
    kill $FRONTEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Frontend-URL: $FRONTEND_URL"

# Stoppe Frontend-ngrok
kill $FRONTEND_PID 2>/dev/null
sleep 2

# Schritt 2: Backend-URL holen
echo ""
echo "📡 Schritt 2: Hole Backend-URL..."
ngrok http 8000 > /tmp/ngrok-backend-temp.log 2>&1 &
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
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo "✅ Backend-URL: $BACKEND_URL"

# Stoppe Backend-ngrok
kill $BACKEND_PID 2>/dev/null
sleep 2

echo ""
echo "🔧 Aktualisiere Konfiguration..."

# Backup
cp docker-compose.yml docker-compose.yml.bak 2>/dev/null

# Aktualisiere docker-compose.yml
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    sed -i '' "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
else
    sed -i "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    sed -i "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
fi

echo "✅ Konfiguration aktualisiert"

echo ""
echo "🛑 Stoppe Container..."
docker compose down

echo ""
echo "🔨 Baue Frontend mit neuer Backend-URL..."
docker compose up --build -d

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ KONFIGURATION ABGESCHLOSSEN"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend-URL: $FRONTEND_URL"
echo "🔧 Backend-URL:  $BACKEND_URL"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo ""
echo "1️⃣  Starte ngrok für Frontend in Terminal 1:"
echo "    ngrok http 3000"
echo ""
echo "2️⃣  Starte ngrok für Backend in Terminal 2:"
echo "    ngrok http 8000"
echo ""
echo "3️⃣  Öffne die Frontend-URL: $FRONTEND_URL"
echo ""
echo "⚠️  WICHTIG: Beide ngrok-Prozesse müssen laufen!"
echo "   Frontend-ngrok: Port 3000"
echo "   Backend-ngrok: Port 8000"
echo ""
echo "════════════════════════════════════════════════════════════"

