# Test-Anleitung für iframe-CORS-Fixes

## ✅ Deployment erfolgreich abgeschlossen!

Die folgenden Änderungen wurden deployed:
- ✅ Backend: CSP frame-ancestors konfiguriert
- ✅ Backend: X-Frame-Options entfernt
- ✅ Frontend: CSP frame-ancestors für Netlify-Domains
- ✅ Frontend: MIME Types korrekt konfiguriert

## 🧪 Test-Schritte

### 1. Direkter Zugriff testen

Öffne im Browser:
- **https://chatbotcarsten.live**
  - ✅ Sollte ohne Fehler laden
  - ✅ Chatbot sollte sichtbar sein
  - ✅ Styling sollte korrekt sein

- **https://chatbotcarsten.live/api/health**
  - ✅ Sollte `{"status":"ok"}` zurückgeben

### 2. iframe-Einbindung testen

1. **Öffne deine Netlify-Seite** mit dem iframe-Code:
   ```html
   <div id="medical-chatbot-container" style="position: fixed; bottom: 0; right: 0; z-index: 9999; pointer-events: none;">
     <iframe 
       src="https://chatbotcarsten.live" 
       style="width: 100vw; height: 100vh; border: none; background: transparent; pointer-events: auto;"
       allow="microphone; camera"
       title="Online-Rezeption Chatbot"
       loading="lazy"
     ></iframe>
   </div>
   ```

2. **Öffne die Browser-Konsole** (F12 → Console Tab)

3. **Prüfe auf Fehler:**
   - ✅ **KEINE** CORS-Fehler wie:
     - `XMLHttpRequest cannot load ... due to access control checks`
     - `Access to fetch at ... has been blocked by CORS policy`
   
   - ✅ **KEINE** MIME-Type-Fehler wie:
     - `Did not parse stylesheet ... because non CSS MIME types are not allowed`
   
   - ✅ **KEINE** iframe-Blockierungs-Fehler wie:
     - `Blocked a frame with origin ... from accessing a frame`
     - `Refused to display ... in a frame because it set 'X-Frame-Options' to 'deny'`

4. **Teste die Funktionalität:**
   - ✅ Chatbot-Button ist sichtbar
   - ✅ Chatbot öffnet sich beim Klick
   - ✅ Session wird erstellt (keine Fehlermeldung)
   - ✅ Nachricht senden funktioniert
   - ✅ Antwort vom Backend kommt an
   - ✅ Styling ist korrekt (Schriftarten, Farben, Layout)

### 3. Network-Tab prüfen

1. Öffne Browser DevTools (F12)
2. Gehe zum **Network** Tab
3. Lade die Seite neu
4. Prüfe die Requests:

   **CSS-Dateien:**
   - ✅ `Content-Type: text/css` (nicht `application/octet-stream` oder `text/plain`)
   - ✅ Status: `200 OK`

   **API-Requests:**
   - ✅ `/api/chat/session` → Status: `201 Created`
   - ✅ `/api/chat/message` → Status: `200 OK`
   - ✅ Response Headers enthalten:
     - `Access-Control-Allow-Origin: https://cosmic-jalebi-b78f17.netlify.app` (oder deine Netlify-Domain)
     - `Access-Control-Allow-Credentials: true`

## 🔍 Erwartete Ergebnisse

Nach erfolgreichem Fix solltest du sehen:

### ✅ Erfolgreich:
- Chatbot lädt im iframe
- Keine Fehler in der Browser-Konsole
- CSS wird korrekt geladen
- Session wird erstellt
- Nachrichten können gesendet werden
- Antworten kommen vom Backend

### ❌ Falls noch Probleme auftreten:

**CORS-Fehler persistieren:**
```bash
# Auf dem Server prüfen:
docker compose exec backend env | grep CORS_ORIGINS
# Sollte enthalten: https://cosmic-jalebi-b78f17.netlify.app
```

**CSS wird nicht geladen:**
```bash
# Prüfe Frontend-Container:
docker compose logs frontend | grep -i mime
```

**iframe wird blockiert:**
```bash
# Prüfe Response Headers:
curl -I https://chatbotcarsten.live
# Sollte KEINEN X-Frame-Options Header haben
```

## 📝 Nächste Schritte

Wenn alles funktioniert:
1. ✅ Chatbot ist im iframe eingebettet
2. ✅ Funktioniert auf deiner Netlify-Seite
3. ✅ Keine Fehler in der Konsole
4. ✅ Vollständige Funktionalität

Falls Probleme auftreten, siehe `IFRAME-CORS-FIX.md` für Troubleshooting.

