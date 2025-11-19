#!/bin/bash

# Einfaches Script zum Starten von ngrok für Frontend und Backend

cd "$(dirname "$0")"

echo "🚀 Starte ngrok für öffentlichen Zugriff..."
echo ""

# Stoppe laufende ngrok-Instanzen
pkill ngrok 2>/dev/null
sleep 2

# Starte Frontend-Tunnel (Port 3000)
echo "📡 Starte Tunnel für Frontend (Port 3000)..."
ngrok http 3000 --log=stdout > /tmp/ngrok-frontend.log 2>&1 &
FRONTEND_PID=$!
sleep 3

# Starte Backend-Tunnel (Port 8000) auf anderem Port
echo "📡 Starte Tunnel für Backend (Port 8000)..."
ngrok http 8000 --log=stdout --web-addr=localhost:4041 > /tmp/ngrok-backend.log 2>&1 &
BACKEND_PID=$!
sleep 3

echo ""
echo "⏳ Warte auf URLs..."
sleep 3

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
" 2>/dev/null)

# Hole Backend-URL
BACKEND_URL=$(curl -s http://localhost:4041/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    if tunnels:
        print(tunnels[0].get('public_url', ''))
except:
    pass
" 2>/dev/null)

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ ÖFFENTLICHE URLs"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "🌐 FRONTEND (Chatbot):"
    echo "   $FRONTEND_URL"
    echo ""
    echo "   👆 Diese URL kannst du teilen!"
    echo ""
else
    echo "⚠️  Frontend-URL nicht gefunden"
    echo "   Prüfe: http://localhost:4040"
fi

if [ -n "$BACKEND_URL" ]; then
    echo "🔧 BACKEND (API):"
    echo "   $BACKEND_URL"
    echo ""
else
    echo "⚠️  Backend-URL nicht gefunden"
    echo "   Prüfe: http://localhost:4041"
fi

echo "════════════════════════════════════════════════════════════"
echo ""

if [ -n "$FRONTEND_URL" ] && [ -n "$BACKEND_URL" ]; then
    echo "⚠️  WICHTIG: Das Frontend muss mit der Backend-URL neu gebaut werden!"
    echo ""
    echo "🔄 Möchtest du das Frontend jetzt neu bauen? (j/n)"
    read -p "   " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        echo ""
        echo "🛑 Stoppe Container..."
        docker compose down
        
        echo "🔨 Aktualisiere docker-compose.yml..."
        # Backup erstellen
        cp docker-compose.yml docker-compose.yml.bak 2>/dev/null
        
        # Aktualisiere Backend-URL (macOS kompatibel)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
        else
            sed -i "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
        fi
        
        echo "🚀 Baue und starte Container neu..."
        docker compose up --build -d
        
        echo ""
        echo "✅ Fertig! Das Frontend ist jetzt mit der Backend-URL konfiguriert."
        echo "🌐 Öffne: $FRONTEND_URL"
    else
        echo ""
        echo "💡 Um das Frontend später neu zu bauen:"
        echo "   1. Stoppe Container: docker compose down"
        echo "   2. Setze VITE_BACKEND_URL in docker-compose.yml auf: $BACKEND_URL"
        echo "   3. Starte neu: docker compose up --build -d"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "💡 Ngrok läuft im Hintergrund"
echo "💡 Frontend Web UI: http://localhost:4040"
echo "💡 Backend Web UI: http://localhost:4041"
echo "💡 Zum Stoppen: pkill ngrok"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "💡 Drücke Enter zum Beenden (ngrok läuft weiter)..."
read

