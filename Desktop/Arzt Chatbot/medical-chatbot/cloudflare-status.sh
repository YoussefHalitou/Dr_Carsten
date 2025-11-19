#!/bin/bash

# Script zum Prüfen des Cloudflare Tunnel Status

cd "$(dirname "$0")"

echo "🔍 Cloudflare Tunnel Status"
echo "════════════════════════════════════════════════════════════"
echo ""

# Prüfe ob cloudflared läuft
CLOUDFLARED_RUNNING=$(ps aux | grep "[c]loudflared tunnel" | wc -l | tr -d ' ')

if [ "$CLOUDFLARED_RUNNING" -eq "0" ]; then
    echo "❌ Keine Cloudflare Tunnels aktiv"
    echo ""
    echo "💡 Starte Tunnels mit: ./start-cloudflare-tunnels.sh"
    exit 1
fi

echo "✅ Cloudflare Tunnels laufen ($CLOUDFLARED_RUNNING Tunnel(s))"
echo ""

# Hole URLs aus gespeicherten Dateien
FRONTEND_URL=$(cat /tmp/cloudflared-frontend.url 2>/dev/null)
BACKEND_URL=$(cat /tmp/cloudflared-backend.url 2>/dev/null)

if [ -n "$FRONTEND_URL" ]; then
    echo "🌐 Frontend-URL:"
    echo "   $FRONTEND_URL"
    echo ""
    # Prüfe ob erreichbar
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Erreichbar (HTTP $HTTP_CODE)"
    else
        echo "   ⚠️  HTTP $HTTP_CODE"
    fi
else
    echo "⚠️  Frontend-URL nicht gefunden"
fi

echo ""

if [ -n "$BACKEND_URL" ]; then
    echo "🔧 Backend-URL:"
    echo "   $BACKEND_URL"
    echo ""
    # Prüfe Health-Check
    HEALTH=$(curl -s "$BACKEND_URL/health" 2>/dev/null)
    if echo "$HEALTH" | grep -q "ok"; then
        echo "   ✅ Erreichbar (Health-Check OK)"
    else
        echo "   ⚠️  Health-Check fehlgeschlagen"
    fi
else
    echo "⚠️  Backend-URL nicht gefunden"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "📋 VERWALTUNG"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🛑 Tunnels stoppen:"
echo "   pkill cloudflared"
echo ""
echo "📋 Logs ansehen:"
echo "   Frontend: tail -f /tmp/cloudflared-frontend.log"
echo "   Backend: tail -f /tmp/cloudflared-backend.log"
echo ""
echo "🔄 Tunnels neu starten:"
echo "   ./start-cloudflare-tunnels.sh"
echo ""

