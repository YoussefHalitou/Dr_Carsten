#!/bin/bash

# Einfaches Script zum Erstellen eines sharebaren Links
# Startet ngrok für Frontend und Backend und zeigt die URLs

cd "$(dirname "$0")"

echo "🚀 Erstelle sharebaren Link für Kunden..."
echo ""

# Prüfe Container
if ! docker compose ps | grep -q "frontend.*Up"; then
    echo "❌ Frontend-Container läuft nicht. Starte zuerst: docker compose up -d"
    exit 1
fi

# Lese Authtoken
CONFIG_FILE="$HOME/Library/Application Support/ngrok/ngrok.yml"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="$HOME/.config/ngrok/ngrok.yml"
fi

AUTHTOKEN=$(grep -A1 "^agent:" "$CONFIG_FILE" 2>/dev/null | grep "authtoken:" | sed "s/.*authtoken:[[:space:]]*'\(.*\)'.*/\1/" || echo "")

if [ -z "$AUTHTOKEN" ]; then
    echo "❌ Authtoken nicht gefunden. Stelle sicher, dass ngrok konfiguriert ist."
    exit 1
fi

# Stoppe alte ngrok-Instanzen
pkill ngrok 2>/dev/null
sleep 2

# Erstelle Config
cat > /tmp/ngrok-link.yml <<EOF
version: "2"
authtoken: $AUTHTOKEN
tunnels:
  frontend:
    addr: 3000
    proto: http
  backend:
    addr: 8000
    proto: http
EOF

echo "📡 Starte ngrok..."
ngrok start --config=/tmp/ngrok-link.yml --all > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
sleep 8

# Hole URLs
TUNNELS=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

FRONTEND_URL=$(echo "$TUNNELS" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for t in data.get('tunnels', []):
        if t.get('name') == 'frontend' or '3000' in str(t.get('config', {}).get('addr', '')):
            print(t.get('public_url', ''))
            break
except: pass
" 2>/dev/null)

BACKEND_URL=$(echo "$TUNNELS" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for t in data.get('tunnels', []):
        if t.get('name') == 'backend' or '8000' in str(t.get('config', {}).get('addr', '')):
            print(t.get('public_url', ''))
            break
except: pass
" 2>/dev/null)

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
    echo "❌ Konnte URLs nicht abrufen. Prüfe: http://localhost:4040"
    pkill ngrok
    exit 1
fi

echo ""
echo "✅ URLs erhalten!"
echo ""
echo "🌐 FRONTEND-URL (teile diese mit deinem Kunden):"
echo "   $FRONTEND_URL"
echo ""
echo "🔧 BACKEND-URL:"
echo "   $BACKEND_URL"
echo ""

# Aktualisiere docker-compose.yml
echo "🔧 Aktualisiere Konfiguration..."
cp docker-compose.yml docker-compose.yml.bak-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    sed -i '' "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
else
    sed -i "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    sed -i "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
fi

echo "🔨 Baue Frontend neu..."
docker compose up --build -d frontend

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ FERTIG!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📧 Teile diese URL mit deinem Kunden:"
echo "   $FRONTEND_URL"
echo ""
echo "⚠️  Ngrok läuft im Hintergrund (PID: $NGROK_PID)"
echo "💡 Ngrok Web UI: http://localhost:4040"
echo "💡 Zum Stoppen: pkill ngrok"
echo ""
echo "════════════════════════════════════════════════════════════"

