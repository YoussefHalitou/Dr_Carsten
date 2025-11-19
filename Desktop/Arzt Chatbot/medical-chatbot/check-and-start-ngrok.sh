#!/bin/bash

# Script zum Prüfen und Starten der ngrok-Tunnels

cd "$(dirname "$0")"

echo "🔍 Prüfe ngrok-Status..."
echo ""

# Prüfe welche ngrok-Tunnels laufen
NGROK_RUNNING=$(ps aux | grep "[n]grok http" | wc -l | tr -d ' ')

if [ "$NGROK_RUNNING" -gt 0 ]; then
    echo "✅ Ngrok läuft bereits"
    ACTIVE_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        config = tunnels[0].get('config', {})
        addr = config.get('addr', '')
        url = tunnels[0].get('public_url', '')
        if '3000' in addr:
            print(f'FRONTEND:{url}')
        elif '8000' in addr:
            print(f'BACKEND:{url}')
        else:
            print(f'UNKNOWN:{url}')
except:
    pass
" 2>/dev/null)
    
    if [[ $ACTIVE_URL == FRONTEND:* ]]; then
        FRONTEND_URL=${ACTIVE_URL#FRONTEND:}
        echo "   Frontend-Tunnel: $FRONTEND_URL"
        echo ""
        echo "⚠️  Backend-Tunnel läuft nicht"
        echo "   Das Frontend ist konfiguriert mit Backend-URL:"
        BACKEND_URL_CONFIG=$(grep "VITE_BACKEND_URL" docker-compose.yml | head -1 | sed 's/.*VITE_BACKEND_URL: //' | sed 's/ *$//')
        echo "   $BACKEND_URL_CONFIG"
        echo ""
        echo "💡 OPTIONEN:"
        echo "   1. Frontend-ngrok stoppen und Backend-ngrok starten"
        echo "   2. Ngrok Paid Plan verwenden (mehrere Tunnels)"
        echo "   3. Frontend-URL teilen (Backend muss separat erreichbar sein)"
    elif [[ $ACTIVE_URL == BACKEND:* ]]; then
        BACKEND_URL=${ACTIVE_URL#BACKEND:}
        echo "   Backend-Tunnel: $BACKEND_URL"
        echo ""
        echo "⚠️  Frontend-Tunnel läuft nicht"
    fi
else
    echo "❌ Ngrok läuft nicht"
    echo ""
    echo "🚀 Starte Frontend-ngrok..."
    ngrok http 3000 > /tmp/ngrok-frontend-check.log 2>&1 &
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
" 2>/dev/null)
    
    if [ -n "$FRONTEND_URL" ]; then
        echo "✅ Frontend-ngrok gestartet: $FRONTEND_URL"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "📋 ZUSAMMENFASSUNG"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend-URL (öffentlich, teilen!):"
if [ -n "$FRONTEND_URL" ]; then
    echo "   $FRONTEND_URL"
else
    echo "   Nicht aktiv"
fi
echo ""
echo "🔧 Backend-URL (aus Config):"
BACKEND_URL_CONFIG=$(grep "VITE_BACKEND_URL" docker-compose.yml | head -1 | sed 's/.*VITE_BACKEND_URL: //' | sed 's/ *$//')
echo "   $BACKEND_URL_CONFIG"
echo ""
echo "⚠️  WICHTIG:"
echo "   ngrok Free Plan unterstützt nur 1 Tunnel gleichzeitig."
echo "   Um beide Tunnels zu verwenden, benötigst du einen Paid Plan."
echo ""
echo "💡 EMPFEHLUNG:"
echo "   Teile die Frontend-URL. Das Backend muss über ngrok"
echo "   erreichbar sein, damit das Frontend funktioniert."
echo ""

