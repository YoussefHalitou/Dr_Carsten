#!/bin/bash

# Schneller Status-Check für Container, Tunnels und URLs

cd "$(dirname "$0")"

echo "🔍 Quick Status Check"
echo "════════════════════════════════════════════════════════════"
echo ""

# 1. Container-Status
echo "1️⃣ Container:"
CONTAINER_STATUS=$(docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
containers = []
try:
    for line in sys.stdin:
        if line.strip():
            containers.append(json.loads(line))
    running = sum(1 for c in containers if c.get('State') == 'running')
    total = len(containers)
    print(f'   {running}/{total} Container laufen')
    if running == total and total > 0:
        print('   ✅ Alle Container laufen')
    elif running > 0:
        print('   ⚠️  Einige Container sind gestoppt')
    else:
        print('   ❌ Keine Container laufen')
except:
    print('   ❌ Konnte Status nicht prüfen')
")

echo "$CONTAINER_STATUS"
echo ""

# 2. Tunnel-Status
echo "2️⃣ Cloudflare Tunnels:"
TUNNEL_COUNT=$(ps aux | grep "[c]loudflared tunnel" | wc -l | tr -d ' ')
if [ "$TUNNEL_COUNT" -eq "2" ]; then
    echo "   ✅ $TUNNEL_COUNT Tunnel(s) aktiv (Frontend + Backend)"
elif [ "$TUNNEL_COUNT" -eq "1" ]; then
    echo "   ⚠️  Nur $TUNNEL_COUNT Tunnel aktiv"
else
    echo "   ❌ Keine Tunnels aktiv"
fi
echo ""

# 3. URLs
echo "3️⃣ URLs:"
FRONTEND_URL=$(cat /tmp/cloudflared-frontend.url 2>/dev/null)
BACKEND_URL=$(cat /tmp/cloudflared-backend.url 2>/dev/null)

if [ -n "$FRONTEND_URL" ]; then
    echo "   Frontend: $FRONTEND_URL"
    # Prüfe Erreichbarkeit
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ Erreichbar"
    else
        echo "   ❌ Nicht erreichbar (HTTP $HTTP_CODE)"
    fi
else
    echo "   ⚠️  Frontend-URL nicht gefunden"
fi

if [ -n "$BACKEND_URL" ]; then
    echo "   Backend: $BACKEND_URL"
    # Prüfe Health-Check
    HEALTH=$(curl -s "$BACKEND_URL/health" 2>/dev/null)
    if echo "$HEALTH" | grep -q "ok"; then
        echo "   ✅ Erreichbar"
    else
        echo "   ❌ Nicht erreichbar"
    fi
else
    echo "   ⚠️  Backend-URL nicht gefunden"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "💡 Tipps:"
echo "   - Container starten: docker compose up -d"
echo "   - Tunnels starten: ./start-cloudflare-tunnels.sh"
echo "   - Status prüfen: ./cloudflare-status.sh"
echo "════════════════════════════════════════════════════════════"

