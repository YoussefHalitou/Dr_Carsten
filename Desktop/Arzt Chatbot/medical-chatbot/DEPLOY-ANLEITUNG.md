# Deployment-Anleitung für iframe-CORS-Fixes

## Option 1: Automatisches Deployment (wenn SSH-Keys konfiguriert sind)

```bash
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
./fix-iframe-cors.sh
```

## Option 2: Manuelles Deployment

### Schritt 1: Dateien auf Server kopieren

**Option A: Mit SCP (wenn SSH-Keys konfiguriert)**
```bash
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
scp backend/main.py root@37.27.12.97:/opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot/backend/main.py
scp frontend/nginx.conf root@37.27.12.97:/opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot/frontend/nginx.conf
```

**Option B: Mit SFTP oder manuell**
1. Verbinde dich mit dem Server (z.B. über SFTP-Client)
2. Kopiere `backend/main.py` nach `/opt/medical-chatbot/Desktop/Arzt Chatbot/medical-chatbot/backend/main.py`
3. Kopiere `frontend/nginx.conf` nach `/opt/medical-chatbot/Desktop/Arzt Chatbot/medical-chatbot/frontend/nginx.conf`

### Schritt 2: Auf dem Server ausführen

**Option A: Mit dem Deployment-Script**
```bash
# Kopiere deploy-iframe-fix-server.sh auf den Server
scp deploy-iframe-fix-server.sh root@37.27.12.97:/tmp/

# Auf dem Server:
ssh root@37.27.12.97
chmod +x /tmp/deploy-iframe-fix-server.sh
/tmp/deploy-iframe-fix-server.sh
```

**Option B: Manuell auf dem Server**
```bash
ssh root@37.27.12.97
cd /opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot

# Rebuild Backend
docker compose build --no-cache backend

# Rebuild Frontend
docker compose build --no-cache frontend

# Restart Services
docker compose restart backend frontend
```

## Schritt 3: Testen

1. **Direkter Zugriff testen:**
   - Öffne `https://chatbotcarsten.live` im Browser
   - Sollte ohne Fehler laden

2. **API testen:**
   - Öffne `https://chatbotcarsten.live/api/health`
   - Sollte `{"status":"ok"}` zurückgeben

3. **iframe-Einbindung testen:**
   - Öffne deine Netlify-Seite mit dem iframe
   - Öffne die Browser-Konsole (F12)
   - Prüfe auf Fehler:
     - ✅ Keine CORS-Fehler
     - ✅ Keine "Not allowed to request resource" Fehler
     - ✅ CSS wird korrekt geladen
     - ✅ Session kann erstellt werden
     - ✅ Chatbot funktioniert

## Troubleshooting

### SSH-Verbindungsprobleme
- Stelle sicher, dass SSH-Keys konfiguriert sind, oder
- Verwende Option 2B (manuelles Deployment)

### Container starten nicht
```bash
# Prüfe Logs
docker compose logs backend
docker compose logs frontend

# Prüfe Container-Status
docker compose ps
```

### Änderungen werden nicht übernommen
- Stelle sicher, dass `--no-cache` beim Build verwendet wird
- Prüfe, ob die Dateien korrekt kopiert wurden:
  ```bash
  cat /opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot/backend/main.py | grep "frame-ancestors"
  ```

