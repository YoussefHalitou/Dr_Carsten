# Öffentlichen Link erstellen

## Schnellstart mit ngrok

### Option 1: Automatisches Script (empfohlen)

```bash
./start-public.sh
```

Das Script startet ngrok für Frontend und Backend und zeigt dir die URLs.

### Option 2: Manuell

#### 1. Frontend-URL erhalten

```bash
# Terminal 1: Starte ngrok für Frontend
ngrok http 3000
```

Du erhältst eine URL wie: `https://xxxx-xxxx.ngrok-free.app`

#### 2. Backend-URL erhalten

```bash
# Terminal 2: Starte ngrok für Backend (auf anderem Port)
ngrok http 8000 --web-addr=localhost:4041
```

Du erhältst eine URL wie: `https://yyyy-yyyy.ngrok-free.app`

#### 3. Frontend mit Backend-URL neu bauen

1. Stoppe die Container:
   ```bash
   docker compose down
   ```

2. Öffne `docker-compose.yml` und ändere:
   ```yaml
   VITE_BACKEND_URL: https://deine-backend-url.ngrok-free.app
   ```

3. Baue und starte neu:
   ```bash
   docker compose up --build -d
   ```

#### 4. Teilen der Frontend-URL

Die **Frontend-URL** (z.B. `https://xxxx-xxxx.ngrok-free.app`) kannst du jetzt teilen!

### Option 3: Nur Frontend (einfacher, aber Backend muss lokal sein)

Wenn du nur das Frontend öffentlich machen willst und das Backend lokal bleiben soll:

1. Starte ngrok nur für Frontend:
   ```bash
   ngrok http 3000
   ```

2. Die Frontend-URL funktioniert, aber nur wenn der Nutzer auch Zugriff auf dein lokales Netzwerk hat (nicht empfohlen für öffentliches Teilen).

## Wichtige Hinweise

- **Ngrok Free Plan**: Die URLs ändern sich bei jedem Neustart von ngrok
- **Ngrok Paid Plan**: Du kannst feste Domains verwenden
- **Sicherheit**: Stelle sicher, dass dein `API_KEY` stark ist
- **Backend muss erreichbar sein**: Das Frontend muss auf das Backend zugreifen können

## Alternative: Railway/anderer Hoster

Für eine permanente Lösung ohne ngrok, verwende Railway oder einen anderen Hoster (siehe README.md).

