#!/bin/bash

# Einfaches Script zum schnellen Starten von ngrok

cd "$(dirname "$0")"

echo "🚀 Quick Ngrok Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe Container
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Container laufen nicht. Starte zuerst: docker compose up -d"
    exit 1
fi

# Stoppe alte ngrok-Instanzen
pkill ngrok 2>/dev/null
sleep 1

echo "📡 Starte ngrok für Frontend..."
ngrok http 3000 > /tmp/ngrok-frontend.log 2>&1 &
FRONTEND_PID=$!

echo "⏳ Warte 5 Sekunden..."
sleep 5

# Hole Frontend-URL
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
    echo "   Öffne http://localhost:4040 manuell"
    exit 1
fi

echo ""
echo "✅ Frontend-URL: $FRONTEND_URL"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "📋 NÄCHSTE SCHRITTE:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Starte Backend-ngrok in einem NEUEN Terminal:"
echo "    ngrok http 8000"
echo ""
echo "2️⃣  Öffne http://localhost:4040 und kopiere die Backend-URL"
echo "    (Die zweite URL in der Liste)"
echo ""
echo "3️⃣  Aktualisiere docker-compose.yml:"
echo "    VITE_BACKEND_URL: <deine-backend-url>"
echo ""
echo "4️⃣  Baue Frontend neu:"
echo "    docker compose down"
echo "    docker compose up --build -d"
echo ""
echo "5️⃣  Teile die Frontend-URL: $FRONTEND_URL"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "💡 Ngrok läuft im Hintergrund (PID: $FRONTEND_PID)"
echo "💡 Web UI: http://localhost:4040"
echo "💡 Zum Stoppen: pkill ngrok"
echo "════════════════════════════════════════════════════════════"

