#!/bin/bash

# Einfaches Script zum Starten von ngrok für Frontend

cd "$(dirname "$0")"

echo "🚀 Starte ngrok für Frontend..."
echo ""

pkill ngrok 2>/dev/null
sleep 1

ngrok http 3000 > /tmp/ngrok-frontend.log 2>&1 &
sleep 5

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

if [ -n "$FRONTEND_URL" ]; then
    echo "✅ Frontend-URL: $FRONTEND_URL"
    echo ""
    echo "🌐 Diese URL kannst du jetzt teilen!"
    echo ""
    echo "📋 Ngrok Web UI: http://localhost:4040"
    echo "💡 Zum Stoppen: pkill ngrok"
    echo ""
    echo "⚠️  WICHTIG: Das Backend muss auch über ngrok erreichbar sein!"
    echo "   Aktuelle Backend-URL in Config: https://cbbbd8f09503.ngrok-free.app"
    echo "   Stelle sicher, dass diese URL erreichbar ist."
else
    echo "❌ Konnte URL nicht abrufen"
fi

