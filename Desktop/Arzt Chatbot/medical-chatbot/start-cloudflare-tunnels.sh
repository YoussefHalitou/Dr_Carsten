#!/bin/bash

# Script zum Starten von Cloudflare Tunnels für Frontend und Backend

cd "$(dirname "$0")"

echo "🚀 Cloudflare Tunnel Setup"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob Container laufen
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Container laufen nicht. Starte zuerst: docker compose up -d"
    exit 1
fi

# Stoppe alte cloudflared-Prozesse
pkill cloudflared 2>/dev/null
sleep 2

echo "📡 Starte Cloudflare Tunnel für Frontend (Port 3000)..."
cloudflared tunnel --url http://localhost:3000 > /tmp/cloudflared-frontend.log 2>&1 &
FRONTEND_TUNNEL_PID=$!

echo "⏳ Warte auf Frontend-URL..."
sleep 8

# Hole Frontend-URL aus Logs
FRONTEND_URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" /tmp/cloudflared-frontend.log 2>/dev/null | head -1)

if [ -z "$FRONTEND_URL" ]; then
    echo "❌ Konnte Frontend-URL nicht finden. Prüfe Logs:"
    tail -10 /tmp/cloudflared-frontend.log
    kill $FRONTEND_TUNNEL_PID 2>/dev/null
    exit 1
fi

echo "✅ Frontend-URL: $FRONTEND_URL"

echo ""
echo "📡 Starte Cloudflare Tunnel für Backend (Port 8000)..."
cloudflared tunnel --url http://localhost:8000 > /tmp/cloudflared-backend.log 2>&1 &
BACKEND_TUNNEL_PID=$!

echo "⏳ Warte auf Backend-URL..."
sleep 8

# Hole Backend-URL aus Logs
BACKEND_URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" /tmp/cloudflared-backend.log 2>/dev/null | head -1)

if [ -z "$BACKEND_URL" ]; then
    echo "❌ Konnte Backend-URL nicht finden. Prüfe Logs:"
    tail -10 /tmp/cloudflared-backend.log
    kill $FRONTEND_TUNNEL_PID $BACKEND_TUNNEL_PID 2>/dev/null
    exit 1
fi

echo "✅ Backend-URL: $BACKEND_URL"

echo ""
echo "🔧 Aktualisiere Konfiguration..."

# Backup
cp docker-compose.yml docker-compose.yml.bak-cloudflare 2>/dev/null

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
echo "✅ CLOUDFLARE TUNNELS AKTIV!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 Frontend-URL (teilen!):"
echo "   $FRONTEND_URL"
echo ""
echo "🔧 Backend-URL:"
echo "   $BACKEND_URL"
echo ""
echo "💡 Beide Tunnels laufen im Hintergrund"
echo "💡 Frontend PID: $FRONTEND_TUNNEL_PID"
echo "💡 Backend PID: $BACKEND_TUNNEL_PID"
echo ""
echo "📋 Zum Stoppen:"
echo "   pkill cloudflared"
echo ""
echo "📋 Logs:"
echo "   Frontend: tail -f /tmp/cloudflared-frontend.log"
echo "   Backend: tail -f /tmp/cloudflared-backend.log"
echo ""
echo "════════════════════════════════════════════════════════════"

# Speichere PIDs für später
echo "$FRONTEND_TUNNEL_PID" > /tmp/cloudflared-frontend.pid
echo "$BACKEND_TUNNEL_PID" > /tmp/cloudflared-backend.pid
echo "$FRONTEND_URL" > /tmp/cloudflared-frontend.url
echo "$BACKEND_URL" > /tmp/cloudflared-backend.url

