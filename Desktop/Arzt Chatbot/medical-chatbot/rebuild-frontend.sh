#!/bin/bash

# Script zum Neubauen und Deployen des Frontends auf dem Server

set -e

echo "🔨 Baue Frontend neu mit korrekter Backend-URL..."

cd /opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot

# Frontend neu bauen
echo "📦 Baue Frontend-Container neu..."
docker compose build frontend

# Frontend neu starten
echo "🚀 Starte Frontend neu..."
docker compose restart frontend

# Warte kurz
sleep 3

# Prüfe ob Frontend läuft
echo "✅ Prüfe Frontend-Status..."
docker compose ps frontend

echo ""
echo "✅ Frontend wurde erfolgreich neu gebaut und deployed!"
echo "🌐 Frontend sollte jetzt unter https://chatbotcarsten.live erreichbar sein"
echo "🔗 Backend-URL: https://chatbotcarsten.live/api"
