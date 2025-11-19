#!/bin/bash

# Script zum Starten von Backend-ngrok

cd "$(dirname "$0")"

echo "🚀 Starte Backend-ngrok (Port 8000)..."
echo ""

# Prüfe ob Frontend-ngrok läuft
if pgrep -f "ngrok http 3000" > /dev/null; then
    echo "⚠️  Frontend-ngrok läuft bereits auf Port 4040"
    echo "   Backend-ngrok wird auf einem anderen Port gestartet (falls möglich)"
    echo ""
fi

# Starte Backend-ngrok
ngrok http 8000

