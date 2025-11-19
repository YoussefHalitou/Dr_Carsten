#!/bin/bash

# Script zum Starten beider ngrok-Tunnels

cd "$(dirname "$0")"

echo "🚀 Starte ngrok für Frontend und Backend..."
echo ""

pkill ngrok 2>/dev/null
sleep 2

# Starte Frontend-ngrok
echo "📡 Starte Frontend-ngrok (Port 3000)..."
ngrok http 3000 > /tmp/ngrok-frontend-both.log 2>&1 &
FRONTEND_PID=$!
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
else
    echo "❌ Konnte Frontend-URL nicht abrufen"
fi

echo ""
echo "📡 Starte Backend-ngrok (Port 8000)..."
echo "   (Hinweis: Beide ngrok-Prozesse laufen, aber nur einer zeigt die Web-UI auf Port 4040)"
echo ""

# Versuche Backend-ngrok zu starten (kann auf Port 4041 laufen, wenn möglich)
# Da ngrok v3 möglicherweise nicht beide gleichzeitig unterstützt, 
# starten wir es trotzdem und der Benutzer kann es manuell überprüfen
ngrok http 8000 > /tmp/ngrok-backend-both.log 2>&1 &
BACKEND_PID=$!
sleep 5

# Versuche Backend-URL zu finden (kann auf Port 4040 oder 4041 sein)
BACKEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for t in tunnels:
        config = t.get('config', {})
        addr = str(config.get('addr', ''))
        if '8000' in addr:
            print(t.get('public_url', ''))
            break
except:
    pass
" 2>/dev/null)

# Versuche auch Port 4041 (falls ngrok es unterstützt)
if [ -z "$BACKEND_URL" ]; then
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
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ NGROK TUNNELS"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "🌐 Frontend-URL: $FRONTEND_URL"
    echo "   👆 Diese URL kannst du teilen!"
else
    echo "⚠️  Frontend-URL nicht gefunden"
fi

echo ""

if [ -n "$BACKEND_URL" ]; then
    echo "🔧 Backend-URL: $BACKEND_URL"
else
    echo "⚠️  Backend-URL nicht automatisch gefunden"
    echo "   Prüfe die Logs: tail -20 /tmp/ngrok-backend-both.log"
    echo "   Oder starte Backend-ngrok manuell in einem neuen Terminal:"
    echo "   ngrok http 8000"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "💡 Ngrok läuft im Hintergrund"
echo "💡 Web UI: http://localhost:4040"
echo "💡 Zum Stoppen: pkill ngrok"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "⚠️  HINWEIS:"
echo "   Falls die Backend-URL nicht gefunden wurde,"
echo "   starte Backend-ngrok manuell in einem neuen Terminal:"
echo "   ngrok http 8000"
echo ""

