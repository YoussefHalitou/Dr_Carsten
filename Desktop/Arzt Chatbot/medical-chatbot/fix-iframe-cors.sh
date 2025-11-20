#!/bin/bash

# Script zum Beheben aller Cross-Origin und Security-Probleme für iframe-Einbindung
# Dieses Script deployt die Änderungen auf den Server und rebuildet die Container

set -e

SERVER_USER="${SERVER_USER:-root}"
SERVER_HOST="${SERVER_HOST:-37.27.12.97}"
PROJECT_DIR="/opt/medical-chatbot/Desktop/Arzt Chatbot/medical-chatbot"

echo "🔧 Behebe Cross-Origin und Security-Probleme für iframe-Einbindung..."
echo ""
echo "📋 Änderungen:"
echo "   1. Backend: CSP frame-ancestors für iframe-Einbindung"
echo "   2. Backend: X-Frame-Options entfernt"
echo "   3. Frontend: CSP frame-ancestors in nginx.conf"
echo "   4. Frontend: MIME Types für CSS/JS korrekt konfiguriert"
echo ""

# Kopiere geänderte Dateien auf den Server
echo "📤 Kopiere Dateien auf den Server..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scp "${SCRIPT_DIR}/backend/main.py" ${SERVER_USER}@${SERVER_HOST}:${PROJECT_DIR}/backend/main.py
scp "${SCRIPT_DIR}/frontend/nginx.conf" ${SERVER_USER}@${SERVER_HOST}:${PROJECT_DIR}/frontend/nginx.conf

# Führe Deployment auf dem Server aus
echo ""
echo "🚀 Führe Deployment auf dem Server aus..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'ENDSSH'
set -e
cd /opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot

echo "🔨 Rebuild Backend..."
docker compose build --no-cache backend

echo "🔨 Rebuild Frontend..."
docker compose build --no-cache frontend

echo "🔄 Restart Backend..."
docker compose restart backend

echo "🔄 Restart Frontend..."
docker compose restart frontend

echo ""
echo "✅ Deployment abgeschlossen!"
echo ""
echo "🧪 Teste die Konfiguration:"
echo "   - https://chatbotcarsten.live (direkt)"
echo "   - https://chatbotcarsten.live/api/health"
echo "   - iframe auf Netlify-Seite einbetten"
echo ""
ENDSSH

echo ""
echo "✅ Alle Änderungen wurden deployed!"
echo ""
echo "📝 Nächste Schritte:"
echo "   1. Teste https://chatbotcarsten.live direkt im Browser"
echo "   2. Teste die iframe-Einbindung auf deiner Netlify-Seite"
echo "   3. Prüfe die Browser-Konsole auf Fehler"
echo ""
echo "🔍 Erwartete Ergebnisse:"
echo "   ✓ Keine CORS-Fehler"
echo "   ✓ Keine 'Not allowed to request resource' Fehler"
echo "   ✓ CSS wird korrekt geladen (keine MIME-Type-Fehler)"
echo "   ✓ Session kann erstellt werden"
echo "   ✓ Chatbot funktioniert im iframe"
echo ""

