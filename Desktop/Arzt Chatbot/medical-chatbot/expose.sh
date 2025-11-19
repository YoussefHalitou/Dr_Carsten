#!/bin/bash

# Einfaches Script zum Exponieren der Anwendung über ngrok

cd "$(dirname "$0")"

echo "🚀 Starte ngrok für öffentlichen Zugriff..."
echo ""

# Prüfe ob Container laufen
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Frontend-Container läuft nicht. Starte zuerst: docker compose up -d"
    exit 1
fi

# Prüfe ob ngrok läuft
if pgrep -x "ngrok" > /dev/null; then
    echo "⚠️  ngrok läuft bereits."
    read -p "Möchtest du es neu starten? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        pkill ngrok
        sleep 2
    else
        echo "Verwende laufende ngrok-Instanz..."
    fi
fi

# Starte ngrok mit Config
echo "📡 Starte ngrok Tunnels (Frontend + Backend)..."
ngrok start --all --config=ngrok.yml > /tmp/ngrok-medical-chatbot.log 2>&1 &
NGROK_PID=$!

echo "⏳ Warte 5 Sekunden auf ngrok..."
sleep 5

# Hole URLs von ngrok API
echo ""
echo "🔍 Hole öffentliche URLs..."

# Warte bis API verfügbar ist
for i in {1..10}; do
    if curl -s http://localhost:4040/api/tunnels > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Hole Tunnel-Informationen
TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

if [ -z "$TUNNELS_JSON" ]; then
    echo "❌ Konnte ngrok API nicht erreichen."
    echo "   Prüfe die Logs: tail -f /tmp/ngrok-medical-chatbot.log"
    kill $NGROK_PID 2>/dev/null
    exit 1
fi

# Extrahiere URLs mit Python (einfacher als bash parsing)
FRONTEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        config = tunnel.get('config', {})
        addr = str(config.get('addr', ''))
        if ':3000' in addr or '3000' in addr:
            print(tunnel.get('public_url', ''))
            break
except Exception as e:
    pass
" 2>/dev/null)

BACKEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        config = tunnel.get('config', {})
        addr = str(config.get('addr', ''))
        if ':8000' in addr or '8000' in addr:
            print(tunnel.get('public_url', ''))
            break
except Exception as e:
    pass
" 2>/dev/null)

# Fallback: Nimm erste beiden URLs
if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
    ALL_URLS=($(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    urls = [t.get('public_url', '') for t in data.get('tunnels', [])]
    for url in urls:
        if url:
            print(url)
except:
    pass
" 2>/dev/null))
    
    if [ ${#ALL_URLS[@]} -ge 2 ]; then
        FRONTEND_URL=${ALL_URLS[0]}
        BACKEND_URL=${ALL_URLS[1]}
    elif [ ${#ALL_URLS[@]} -eq 1 ]; then
        FRONTEND_URL=${ALL_URLS[0]}
        echo "⚠️  Nur ein Tunnel gefunden. Möglicherweise läuft ngrok bereits mit anderer Config."
    fi
fi

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
fi

if [ -n "$BACKEND_URL" ]; then
    echo "🔧 BACKEND (API):"
    echo "   $BACKEND_URL"
    echo ""
else
    echo "⚠️  Backend-URL nicht gefunden"
fi

echo "📋 Ngrok Web Interface: http://localhost:4040"
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
        cp docker-compose.yml docker-compose.yml.bak
        
        # Aktualisiere Backend-URL
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
        else
            # Linux
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
echo "💡 Ngrok läuft im Hintergrund (PID: $NGROK_PID)"
echo "💡 Zum Stoppen: pkill ngrok"
echo "💡 Logs: tail -f /tmp/ngrok-medical-chatbot.log"
echo "════════════════════════════════════════════════════════════"

