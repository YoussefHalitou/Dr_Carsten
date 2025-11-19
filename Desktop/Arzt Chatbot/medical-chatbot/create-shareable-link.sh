#!/bin/bash

# Script zum Erstellen eines sharebaren Links für Kunden
# Startet ngrok für Frontend und Backend, aktualisiert die Konfiguration
# und zeigt die sharebare URL an

set -e

cd "$(dirname "$0")"

echo "🚀 Erstelle sharebaren Link für Kunden..."
echo ""

# Prüfe ob ngrok installiert ist
if ! command -v ngrok &> /dev/null; then
    echo "❌ Ngrok ist nicht installiert."
    echo "   Installiere ngrok: brew install ngrok/ngrok/ngrok"
    echo "   Oder lade es herunter von: https://ngrok.com/download"
    exit 1
fi

# Prüfe ob Container laufen
if ! docker compose ps | grep -q "medical-chatbot-frontend.*Up"; then
    echo "❌ Frontend-Container läuft nicht."
    echo "   Starte zuerst: docker compose up -d"
    exit 1
fi

if ! docker compose ps | grep -q "medical-chatbot-backend.*Up"; then
    echo "❌ Backend-Container läuft nicht."
    echo "   Starte zuerst: docker compose up -d"
    exit 1
fi

# Stoppe alte ngrok-Instanzen
echo "🛑 Stoppe alte ngrok-Instanzen..."
pkill ngrok 2>/dev/null || true
sleep 2

# Starte beide Tunnels
echo "📡 Starte ngrok-Tunnels für Frontend und Backend..."

# Lese Authtoken aus der Standard-ngrok-Config
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DEFAULT_NGROK_CONFIG="$HOME/Library/Application Support/ngrok/ngrok.yml"
else
    # Linux
    DEFAULT_NGROK_CONFIG="$HOME/.config/ngrok/ngrok.yml"
fi

AUTHTOKEN=""
if [ -f "$DEFAULT_NGROK_CONFIG" ]; then
    # Extrahiere Authtoken (kann unter 'authtoken:' oder 'agent.authtoken:' sein)
    # Versuche zuerst direkte authtoken-Zeile
    AUTHTOKEN=$(grep -i "^authtoken:" "$DEFAULT_NGROK_CONFIG" 2>/dev/null | head -1 | sed 's/^authtoken:[[:space:]]*//' | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r\n' || echo "")
    
    # Wenn nicht gefunden, versuche agent.authtoken (Version 3)
    if [ -z "$AUTHTOKEN" ]; then
        AUTHTOKEN=$(grep -A1 "^agent:" "$DEFAULT_NGROK_CONFIG" 2>/dev/null | grep -i "authtoken:" | sed 's/.*authtoken:[[:space:]]*//' | sed "s/^'//" | sed "s/'$//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r\n' || echo "")
    fi
    
    # Alternativ: Verwende Python um YAML zu parsen (robuster, falls yaml Modul verfügbar)
    if [ -z "$AUTHTOKEN" ] && command -v python3 &> /dev/null; then
        AUTHTOKEN=$(python3 <<PYEOF 2>/dev/null | tr -d '\r\n' || echo ""
import yaml
import sys
import os
try:
    config_path = os.path.expanduser('$DEFAULT_NGROK_CONFIG')
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    if config:
        # Versuche authtoken direkt
        if 'authtoken' in config:
            print(config['authtoken'])
        # Versuche agent.authtoken (Version 3)
        elif 'agent' in config and isinstance(config['agent'], dict) and 'authtoken' in config['agent']:
            print(config['agent']['authtoken'])
except:
    pass
PYEOF
)
    fi
fi

if [ -z "$AUTHTOKEN" ]; then
    echo "⚠️  WARNUNG: Authtoken nicht gefunden in der Standard-ngrok-Config."
    echo "   Stelle sicher, dass ngrok authentifiziert ist: ngrok config check"
    echo "   Oder konfiguriere ngrok: ngrok config add-authtoken <token>"
    exit 1
fi

# Erstelle temporäre ngrok-Konfiguration mit Authtoken
echo "   Erstelle ngrok-Konfiguration..."
cat > /tmp/ngrok-shareable.yml <<EOF
version: "2"
EOF

if [ -n "$AUTHTOKEN" ]; then
    # Für Version 2: authtoken direkt unter version
    echo "authtoken: $AUTHTOKEN" >> /tmp/ngrok-shareable.yml
fi

cat >> /tmp/ngrok-shareable.yml <<'EOF'
tunnels:
  frontend:
    addr: 3000
    proto: http
  backend:
    addr: 8000
    proto: http
EOF

# Starte beide Tunnels
ngrok start --config=/tmp/ngrok-shareable.yml --all --log=stdout > /tmp/ngrok-all.log 2>&1 &
NGROK_PID=$!

sleep 3

# Prüfe ob ngrok erfolgreich gestartet wurde
if ! kill -0 $NGROK_PID 2>/dev/null; then
    echo "❌ Ngrok konnte nicht gestartet werden."
    echo "   Prüfe die Log-Datei: cat /tmp/ngrok-all.log"
    echo ""
    echo "   Fehlerdetails:"
    cat /tmp/ngrok-all.log 2>/dev/null | tail -10
    echo ""
    echo "   💡 Stelle sicher, dass ngrok korrekt installiert und authentifiziert ist:"
    echo "      ngrok config check"
    exit 1
fi

# Prüfe ob ngrok einen Fehler beim Start hatte
if grep -qi "error\|failed\|authentication" /tmp/ngrok-all.log 2>/dev/null; then
    echo "⚠️  Warnung: Möglicherweise Fehler beim Start von ngrok."
    echo "   Prüfe die Log-Datei: cat /tmp/ngrok-all.log"
    sleep 2
fi

echo "⏳ Warte auf ngrok-URLs (10 Sekunden)..."
sleep 10

# Hole URLs über ngrok API - beide Tunnels sollten über Port 4040 verfügbar sein
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    ALL_TUNNELS_JSON=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null)
    
    if [ -n "$ALL_TUNNELS_JSON" ]; then
        # Parse Frontend-URL (Port 3000 oder Name 'frontend')
        FRONTEND_URL=$(echo "$ALL_TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        name = tunnel.get('name', '').lower()
        config_addr = str(tunnel.get('config', {}).get('addr', ''))
        # Suche nach Frontend (Port 3000 oder Name 'frontend')
        if 'frontend' in name or '3000' in config_addr:
            url = tunnel.get('public_url', '')
            if url:
                print(url)
                sys.exit(0)
    # Fallback: erster Tunnel
    if len(tunnels) > 0:
        print(tunnels[0].get('public_url', ''))
except:
    pass
" 2>/dev/null)
        
        # Parse Backend-URL (Port 8000 oder Name 'backend')
        BACKEND_URL=$(echo "$ALL_TUNNELS_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        name = tunnel.get('name', '').lower()
        config_addr = str(tunnel.get('config', {}).get('addr', ''))
        # Suche nach Backend (Port 8000 oder Name 'backend')
        if 'backend' in name or '8000' in config_addr:
            url = tunnel.get('public_url', '')
            if url:
                print(url)
                sys.exit(0)
    # Fallback: zweiter Tunnel wenn vorhanden
    if len(tunnels) > 1:
        print(tunnels[1].get('public_url', ''))
    # Fallback: erster Tunnel wenn er Port 8000 hat
    elif len(tunnels) == 1:
        config_addr = str(tunnels[0].get('config', {}).get('addr', ''))
        if '8000' in config_addr:
            print(tunnels[0].get('public_url', ''))
except:
    pass
" 2>/dev/null)
        
        # Wenn beide URLs gefunden wurden, breche ab
        if [ -n "$FRONTEND_URL" ] && [ -n "$BACKEND_URL" ] && [ "$FRONTEND_URL" != "$BACKEND_URL" ]; then
            break
        fi
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "   Versuch $RETRY_COUNT/$MAX_RETRIES - warte 3 Sekunden..."
        sleep 3
    fi
done

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
    echo ""
    echo "❌ Konnte ngrok-URLs nicht abrufen."
    echo "   Ngrok Web UI: http://localhost:4040"
    echo "   Log: cat /tmp/ngrok-all.log"
    echo ""
    echo "   Versuche die URLs manuell zu öffnen: http://localhost:4040"
    echo "   Oder prüfe die Log-Datei für Details."
    kill $NGROK_PID 2>/dev/null || true
    exit 1
fi

if [ "$FRONTEND_URL" = "$BACKEND_URL" ]; then
    echo ""
    echo "⚠️  WARNUNG: Frontend- und Backend-URL sind identisch!"
    echo "   Dies sollte nicht passieren. Prüfe die ngrok-Konfiguration."
    echo "   Ngrok Web UI: http://localhost:4040"
    kill $NGROK_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "✅ URLs erhalten:"
echo "   Frontend: $FRONTEND_URL"
echo "   Backend:  $BACKEND_URL"
echo ""

# Backup docker-compose.yml
echo "💾 Erstelle Backup von docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.bak-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Aktualisiere docker-compose.yml
echo "🔧 Aktualisiere docker-compose.yml..."

# macOS und Linux kompatibel
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Aktualisiere VITE_BACKEND_URL
    sed -i '' "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    
    # Aktualisiere CORS_ORIGINS (behalte localhost und füge neue Frontend-URL hinzu)
    if grep -q "CORS_ORIGINS:" docker-compose.yml; then
        sed -i '' "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
    else
        # Füge CORS_ORIGINS hinzu wenn es nicht existiert
        sed -i '' "/ENFORCE_HTTPS:/a\\
      CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL
" docker-compose.yml
    fi
else
    # Linux
    sed -i "s|VITE_BACKEND_URL:.*|VITE_BACKEND_URL: $BACKEND_URL|g" docker-compose.yml
    if grep -q "CORS_ORIGINS:" docker-compose.yml; then
        sed -i "s|CORS_ORIGINS:.*|CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL|g" docker-compose.yml
    else
        sed -i "/ENFORCE_HTTPS:/a\      CORS_ORIGINS: http://localhost:3000,$FRONTEND_URL" docker-compose.yml
    fi
fi

echo "✅ Konfiguration aktualisiert"
echo ""

# Baue Frontend neu
echo "🔨 Baue Frontend mit neuer Backend-URL neu..."
docker compose up --build -d frontend

echo ""
echo "⏳ Warte auf Frontend-Build (15 Sekunden)..."
sleep 15

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ SHAREABARE URL ERSTELLT!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🌐 FRONTEND-URL (Kunde kann diese öffnen):"
echo "   $FRONTEND_URL"
echo ""
echo "🔧 BACKEND-URL (intern):"
echo "   $BACKEND_URL"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 WICHTIGE HINWEISE:"
echo ""
echo "   ⚠️  Ngrok läuft im Hintergrund (PID: $NGROK_PID)"
echo "   ⚠️  Diese URL ist nur gültig, solange ngrok läuft"
echo "   ⚠️  Bei jedem Neustart von ngrok ändert sich die URL (Free Plan)"
echo ""
echo "   💡 Ngrok Web UI: http://localhost:4040"
echo "   💡 Zum Stoppen: pkill ngrok"
echo ""
echo "   📧 Teile diese URL mit deinem Kunden:"
echo "      $FRONTEND_URL"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
