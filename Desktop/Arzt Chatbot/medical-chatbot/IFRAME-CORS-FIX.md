# Cross-Origin und Security-Fixes für iframe-Einbindung

Dieses Dokument beschreibt die Änderungen, die vorgenommen wurden, um den Chatbot in einem iframe auf externen Websites (z.B. Netlify) einzubetten.

## Problem

Beim Einbetten von `https://chatbotcarsten.live` in einem iframe auf einer Netlify-Website traten folgende Fehler auf:

1. **CORS-Fehler**: `XMLHttpRequest cannot load http://37.27.12.97:8000/api/chat/session due to access control checks`
2. **CSS MIME-Type-Fehler**: `Did not parse stylesheet ... because non CSS MIME types are not allowed in strict mode`
3. **X-Frame-Options**: Browser blockierte iframe-Einbindung
4. **CSP**: Content-Security-Policy blockierte iframe-Einbindung

## Lösung

### 1. Backend (`backend/main.py`)

#### CSP frame-ancestors
- **Änderung**: CSP wurde erweitert, um `frame-ancestors` zu erlauben
- **Warum**: Ermöglicht die Einbindung des Chatbots in iframes von erlaubten Origins
- **Konfiguration**: Dynamisch basierend auf `CORS_ORIGINS` aus Settings

```python
frame_ancestors = ["'self'"]
for allowed_origin in allowed_origins:
    if allowed_origin not in frame_ancestors:
        frame_ancestors.append(allowed_origin)
```

#### X-Frame-Options entfernt
- **Änderung**: `X-Frame-Options` Header wurde entfernt
- **Warum**: Konflikt mit CSP `frame-ancestors`. CSP ist die modernere und flexiblere Methode
- **Hinweis**: CSP `frame-ancestors` hat Vorrang und ist granularer konfigurierbar

### 2. Frontend (`frontend/nginx.conf`)

#### CSP frame-ancestors
- **Änderung**: CSP `frame-ancestors` wurde hinzugefügt
- **Konfiguration**: Erlaubt Einbindung von:
  - `'self'` (chatbotcarsten.live selbst)
  - `https://chatbotcarsten.live`
  - `https://cosmic-jalebi-b78f17.netlify.app`
  - `https://*.netlify.app` (alle Netlify-Subdomains)

```nginx
add_header Content-Security-Policy "frame-ancestors 'self' https://chatbotcarsten.live https://cosmic-jalebi-b78f17.netlify.app https://*.netlify.app" always;
```

#### MIME Types
- **Status**: Bereits korrekt konfiguriert
- **Konfiguration**: 
  ```nginx
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  ```
- **Ergebnis**: CSS wird mit `Content-Type: text/css` serviert, JS mit `Content-Type: application/javascript`

### 3. CORS-Konfiguration

#### FastAPI CORSMiddleware
- **Status**: Bereits korrekt konfiguriert
- **Funktionsweise**: FastAPI setzt `Access-Control-Allow-Origin` dynamisch basierend auf dem `Origin`-Header des Requests
- **Konfiguration** (`docker-compose.yml`):
  ```yaml
  CORS_ORIGINS: http://localhost:3000,https://cosmic-jalebi-b78f17.netlify.app,https://chatbotcarsten.live
  ```
- **Wichtig**: `allow_credentials=True` ist gesetzt, was für Cookies (falls zukünftig verwendet) erforderlich ist

#### Preflight Requests (OPTIONS)
- **Status**: Bereits korrekt behandelt
- **Konfiguration**: `dependencies.py` erlaubt OPTIONS-Requests ohne API-Key und HTTPS-Enforcement

### 4. Cookies (Zukunft)

**Aktuell**: Keine Cookies werden verwendet. Sessions werden nur in der Datenbank gespeichert.

**Falls zukünftig Cookies benötigt werden**:
- `SameSite=None` (erforderlich für Cross-Site-Requests in iframes)
- `Secure` (erforderlich für HTTPS)
- Beispiel:
  ```python
  response.set_cookie(
      "session_id",
      value=session_id,
      httponly=True,
      secure=True,
      samesite="none"
  )
  ```

## Konfiguration

### Erlaubte Origins

Die erlaubten Origins werden in `docker-compose.yml` definiert:

```yaml
CORS_ORIGINS: http://localhost:3000,https://cosmic-jalebi-b78f17.netlify.app,https://chatbotcarsten.live
```

**Neue Origins hinzufügen**:
1. `docker-compose.yml` bearbeiten
2. Origin zur `CORS_ORIGINS` Liste hinzufügen
3. Frontend `nginx.conf` anpassen (CSP `frame-ancestors`)
4. Backend und Frontend rebuilden:
   ```bash
   docker compose build --no-cache backend frontend
   docker compose restart backend frontend
   ```

## Deployment

### Automatisches Deployment

```bash
./fix-iframe-cors.sh
```

### Manuelles Deployment

1. **Dateien auf Server kopieren**:
   ```bash
   scp backend/main.py root@37.27.12.97:/opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot/backend/
   scp frontend/nginx.conf root@37.27.12.97:/opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot/frontend/
   ```

2. **Auf dem Server**:
   ```bash
   cd /opt/medical-chatbot/Desktop/Arzt\ Chatbot/medical-chatbot
   docker compose build --no-cache backend frontend
   docker compose restart backend frontend
   ```

## Testing

### 1. Direkter Zugriff
- ✅ `https://chatbotcarsten.live` sollte funktionieren
- ✅ `https://chatbotcarsten.live/api/health` sollte `{"status":"ok"}` zurückgeben

### 2. iframe-Einbindung
- ✅ Keine CORS-Fehler in der Browser-Konsole
- ✅ Keine "Not allowed to request resource" Fehler
- ✅ CSS wird korrekt geladen (keine MIME-Type-Fehler)
- ✅ Session kann erstellt werden
- ✅ Chatbot funktioniert vollständig

### 3. Browser-Konsole prüfen
- Keine roten Fehler
- Keine CORS-Warnungen
- Keine Mixed-Content-Warnungen
- CSS-Dateien werden geladen

## Troubleshooting

### CORS-Fehler persistieren
1. Prüfe `CORS_ORIGINS` in `docker-compose.yml`
2. Prüfe, ob `.env` Datei `CORS_ORIGINS` überschreibt (sollte entfernt werden)
3. Backend rebuilden: `docker compose build --no-cache backend`

### CSS wird nicht geladen
1. Prüfe `frontend/nginx.conf` - `include /etc/nginx/mime.types;` muss vorhanden sein
2. Frontend rebuilden: `docker compose build --no-cache frontend`

### iframe wird blockiert
1. Prüfe Browser-Konsole auf CSP-Fehler
2. Prüfe `frame-ancestors` in Backend und Frontend
3. Prüfe, ob `X-Frame-Options` Header noch gesetzt wird (sollte entfernt sein)

## Sicherheitshinweise

- **CSP frame-ancestors**: Beschränkt, welche Websites den Chatbot einbetten können
- **CORS**: Beschränkt, welche Origins API-Requests stellen können
- **HTTPS**: Erforderlich für `SameSite=None` Cookies (falls zukünftig verwendet)
- **API-Key**: Wird weiterhin für alle API-Requests benötigt

## Referenzen

- [MDN: Content-Security-Policy frame-ancestors](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/frame-ancestors)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [FastAPI CORS](https://fastapi.tiangolo.com/tutorial/cors/)
- [MDN: SameSite Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)

