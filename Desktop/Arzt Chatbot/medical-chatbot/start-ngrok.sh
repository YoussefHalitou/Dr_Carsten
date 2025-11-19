#!/bin/bash

# Script zum Starten von ngrok und Erstellen eines sharebaren Links
# Startet ngrok für Frontend und zeigt die sharebare URL an

cd "$(dirname "$0")"

echo "🚀 Erstelle sharebaren ngrok-Link..."
echo ""

# Prüfe ob Container laufen
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Frontend-Container läuft nicht."
    echo "   Starte zuerst: docker compose up -d"
    exit 1
fi

# Prüfe ob ngrok installiert ist
if ! command -v ngrok &> /dev/null; then
    echo "❌ Ngrok ist nicht installiert."
    echo "   Installiere ngrok: brew install ngrok/ngrok/ngrok"
    echo "   Oder lade es herunter von: https://ngrok.com/download"
    exit 1
fi

# Stoppe laufende ngrok-Instanzen
echo "🛑 Stoppe alte ngrok-Instanzen..."
pkill ngrok 2>/dev/null || true
sleep 2

echo "📡 Starte ngrok für Frontend (Port 3000)..."
echo ""

# Starte ngrok im Hintergrund
ngrok http 3000 > /tmp/ngrok-frontend.log 2>&1 &
NGROK_PID=$!

# Warte auf ngrok-Start
echo "⏳ Warte auf ngrok-Start (5 Sekunden)..."
sleep 5

# Prüfe ob ngrok läuft
if ! kill -0 $NGROK_PID 2>/dev/null; then
    echo "❌ Ngrok konnte nicht gestartet werden."
    echo "   Prüfe die Log-Datei: cat /tmp/ngrok-frontend.log"
    exit 1
fi

# Hole die URL über die ngrok API
MAX_RETRIES=5
RETRY_COUNT=0
FRONTEND_URL=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
    
    if [ -n "$TUNNELS_JSON" ]; then
        FRONTEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        url = tunnel.get('public_url', '')
        if url and url.startswith('http'):
            print(url)
            sys.exit(0)
except:
    pass
" 2>/dev/null)
        
        if [ -n "$FRONTEND_URL" ]; then
            break
        fi
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        sleep 2
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ SHAREABARE URL ERSTELLT!"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "🌐 FRONTEND-URL (teile diese mit deinem Kunden):"
    echo ""
    echo "   $FRONTEND_URL"
    echo ""
    
    # Versuche URL in die Zwischenablage zu kopieren (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$FRONTEND_URL" | pbcopy 2>/dev/null && echo "✅ URL wurde in die Zwischenablage kopiert!"
        echo ""
    fi
else
    echo "⚠️  Konnte URL nicht automatisch abrufen."
    echo "   Öffne http://localhost:4040 in deinem Browser"
    echo "   um die URL manuell zu sehen."
    echo ""
fi

echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 WICHTIGE HINWEISE:"
echo ""
echo "   ⚠️  Ngrok läuft im Hintergrund (PID: $NGROK_PID)"
echo "   ⚠️  Diese URL ist nur gültig, solange ngrok läuft"
echo "   ⚠️  Bei jedem Neustart ändert sich die URL (Free Plan)"
echo ""
echo "   💡 Ngrok Web UI: http://localhost:4040"
echo "   💡 Zum Stoppen: pkill ngrok"
echo ""
echo "   ⚠️  WICHTIG: Du musst auch das Backend über ngrok exponieren!"
echo "      Öffne ein NEUES Terminal und führe aus:"
echo "      ngrok http 8000 --web-addr=localhost:4041"
echo ""
echo "      Dann aktualisiere docker-compose.yml mit der Backend-URL"
echo "      und baue das Frontend neu: docker compose up --build -d"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "💡 Ngrok läuft jetzt im Hintergrund (PID: $NGROK_PID)"
echo "💡 Zum Stoppen: pkill ngrok"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
