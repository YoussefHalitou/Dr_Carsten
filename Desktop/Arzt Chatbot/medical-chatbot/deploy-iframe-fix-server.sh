#!/bin/bash

# Script zum Ausführen auf dem Server
# Kopiere dieses Script auf den Server und führe es aus

set -e

PROJECT_DIR="/opt/medical-chatbot/Desktop/Arzt Chatbot/medical-chatbot"

echo "🔧 Behebe Cross-Origin und Security-Probleme für iframe-Einbindung..."
echo ""

cd "$PROJECT_DIR"

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
echo "🔍 Erwartete Ergebnisse:"
echo "   ✓ Keine CORS-Fehler"
echo "   ✓ Keine 'Not allowed to request resource' Fehler"
echo "   ✓ CSS wird korrekt geladen (keine MIME-Type-Fehler)"
echo "   ✓ Session kann erstellt werden"
echo "   ✓ Chatbot funktioniert im iframe"
echo ""

