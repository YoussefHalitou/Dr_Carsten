#!/bin/bash

# Script zum Neubauen des Frontends mit ngrok Backend-URL

cd "$(dirname "$0")"

echo "🔍 Prüfe ngrok Backend-URL..."

# Hole Backend-URL von ngrok API
TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)

if [ -z "$TUNNELS_JSON" ]; then
    echo "❌ ngrok läuft nicht oder API nicht erreichbar."
    echo "   Bitte starte zuerst: ./start-ngrok.sh"
    exit 1
fi

# Extrahiere Backend-URL (Port 8000)
BACKEND_URL=$(echo "$TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        addr = str(tunnel.get('config', {}).get('addr', ''))
        if '8000' in addr:
            print(tunnel.get('public_url', ''))
            break
except:
    pass
" 2>/dev/null)

# Fallback: Versuche alle URLs
if [ -z "$BACKEND_URL" ]; then
    ALL_URLS=($(echo "$TUNNELS_JSON" | grep -o '"public_url":"https://[^"]*"' | cut -d'"' -f4))
    if [ ${#ALL_URLS[@]} -ge 2 ]; then
        BACKEND_URL=${ALL_URLS[1]}
    elif [ ${#ALL_URLS[@]} -eq 1 ]; then
        BACKEND_URL=${ALL_URLS[0]}
    fi
fi

if [ -z "$BACKEND_URL" ]; then
    echo "❌ Konnte Backend-URL nicht finden."
    echo "   Bitte gib die Backend-URL manuell ein:"
    read -p "Backend URL: " BACKEND_URL
fi

echo "✅ Backend URL: $BACKEND_URL"
echo ""
echo "🛑 Stoppe Container..."
docker compose down

echo ""
echo "🔨 Baue Frontend mit neuer Backend-URL..."

# Aktualisiere docker-compose.yml temporär
sed -i.bak "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml

echo "🚀 Starte Container neu..."
docker compose up --build -d

echo ""
echo "✅ Frontend wurde mit Backend-URL neu gebaut: $BACKEND_URL"
echo "🌐 Frontend sollte jetzt über ngrok erreichbar sein!"

# Stelle Backup wieder her (optional)
# rm -f docker-compose.yml.bak

