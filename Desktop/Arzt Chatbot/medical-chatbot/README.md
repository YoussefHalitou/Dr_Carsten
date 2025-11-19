# Medical Chatbot - Deployment Guide

## Voraussetzungen

- Docker und Docker Compose installiert
- OpenAI API Key
- ngrok installiert (für öffentlichen Zugriff)
- Optional: VPS für 24/7 Betrieb

## Schnellstart

### 1. Environment-Variablen einrichten

Erstelle eine `.env` Datei im `medical-chatbot` Verzeichnis:

```bash
cd medical-chatbot
```

Erstelle die `.env` Datei mit folgendem Inhalt:

```env
OPENAI_API_KEY=dein-openai-api-key
API_KEY=dein-geheimer-api-key
```

**Wichtig**: Der `API_KEY` muss derselbe sein, den das Frontend verwendet (wird über `docker-compose.yml` automatisch weitergegeben).

### 2. Docker Container starten

```bash
docker compose up --build
```

Dies startet:
- **PostgreSQL Datenbank** auf Port 5432 (intern)
- **Backend API** auf http://localhost:8000
- **Frontend** auf http://localhost:3000

### 3. Anwendung verwenden

- **Frontend**: Öffne http://localhost:3000 im Browser
- **Backend API Docs**: Öffne http://localhost:8000/docs für die Swagger UI

### 4. Container stoppen

```bash
docker compose down
```

Um auch die Datenbank-Daten zu löschen:

```bash
docker compose down -v
```

## Troubleshooting

### Port bereits belegt

Falls Port 3000 oder 8000 bereits belegt sind, ändere die Ports in `docker-compose.yml`:

```yaml
ports:
  - '3001:80'  # Frontend auf Port 3001
  - '8001:8000'  # Backend auf Port 8001
```

Vergiss nicht, `VITE_BACKEND_URL` im Frontend-Build anzupassen!

### Datenbank-Verbindungsfehler

Stelle sicher, dass der `DATABASE_URL` in der `docker-compose.yml` korrekt ist. Für lokales Hosting sollte er sein:
```
postgresql+asyncpg://postgres:postgres@db:5432/medical_chatbot
```

### Frontend kann Backend nicht erreichen

Stelle sicher, dass:
1. `VITE_BACKEND_URL` in `docker-compose.yml` auf `http://localhost:8000` gesetzt ist
2. Der `API_KEY` in `.env` und im Frontend-Build identisch ist
3. CORS in der Backend-Konfiguration `http://localhost:3000` erlaubt

## Entwicklungsmodus

Für Entwicklung ohne Docker:

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## Deployment-Optionen

### 🚀 Option 1: VPS Deployment (24/7 Betrieb, empfohlen)

Für produktiven Betrieb auf einem VPS:

```bash
# VPS Setup (einmalig)
./setup-vps.sh

# App deployen
./deploy-to-vps.sh user@vps-ip
```

**Vorteile:**
- ✅ Läuft 24/7
- ✅ Stabile Verbindung
- ✅ Professioneller Betrieb
- ✅ Domain + SSL möglich

**Siehe:** `VPS-DEPLOYMENT.md` für detaillierte Anleitung

### 🌐 Option 2: Cloudflare Tunnel (lokal, kostenlos, mehrere Tunnels):

```bash
./start-cloudflare-tunnels.sh
```

Dieses Script:
- ✅ Startet Cloudflare Tunnel für Frontend und Backend
- ✅ Holt automatisch die URLs
- ✅ Konfiguriert das Frontend mit der Backend-URL
- ✅ Aktualisiert CORS-Einstellungen
- ✅ Baut das Frontend neu
- ✅ Zeigt dir die teilbare Frontend-URL

**Vorteile:**
- ✅ Kostenlos
- ✅ Mehrere Tunnels gleichzeitig
- ✅ Keine Anmeldung erforderlich
- ✅ Stabil und schnell

**Status prüfen:**
```bash
./cloudflare-status.sh
```

**Tunnels stoppen:**
```bash
pkill cloudflared
```

### 🔧 Ngrok (Alternative):

```bash
./setup-ngrok.sh
```

**Hinweis:** Ngrok Free Plan unterstützt nur 1 Tunnel gleichzeitig. Für mehrere Tunnels benötigst du einen Paid Plan.

### ⚠️ Wichtige Hinweise:

- **Cloudflare Tunnel**: URLs ändern sich bei jedem Neustart → Script erneut ausführen
- **Tunnels müssen laufen**: Lasse cloudflared-Prozesse laufen (im Hintergrund)
- **Container müssen laufen**: `docker compose ps` prüfen
- **Bei Neustart**: Führe `./start-cloudflare-tunnels.sh` erneut aus

## Umgebungsvariablen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `OPENAI_API_KEY` | OpenAI API Schlüssel (erforderlich) | - |
| `API_KEY` | API Schlüssel für Authentifizierung (erforderlich) | - |
| `DATABASE_URL` | PostgreSQL Verbindungs-URL | Wird von docker-compose.yml gesetzt |
| `PORT` | Backend Port | 8000 |
| `CORS_ORIGINS` | Erlaubte CORS Origins | http://localhost:3000 |
| `ENFORCE_HTTPS` | HTTPS erzwingen | false (lokal) |
| `DEBUG` | Debug-Modus | false |
| `SQLALCHEMY_ECHO` | SQL-Queries loggen | false |
