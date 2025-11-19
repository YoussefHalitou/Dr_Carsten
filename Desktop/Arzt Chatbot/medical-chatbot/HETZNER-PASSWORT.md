# Hetzner VPS Passwort finden

## Wo finde ich mein Passwort?

### Option 1: Im Hetzner Cloud Dashboard

1. **Gehe zu Hetzner Cloud Console:**
   - https://console.hetzner.cloud/
   - Oder: https://cloud.hetzner.com/

2. **Melde dich an** mit deinem Hetzner-Account

3. **Öffne deinen Server:**
   - Klicke auf "Servers" (oder "Server")
   - Klicke auf deinen Server (z.B. "ubuntu-4gb-hel1-3")

4. **Passwort anzeigen:**
   - Gehe zum Tab "Access" (oder "Zugriff")
   - Unter "Root Password" (oder "Root-Passwort")
   - Klicke auf "Show Password" (oder "Passwort anzeigen")
   - **Das Passwort wird angezeigt**

### Option 2: Passwort zurücksetzen

Falls das Passwort nicht angezeigt wird oder du es nicht findest:

1. **Im Hetzner Dashboard:**
   - Gehe zu deinem Server
   - Tab "Access" (oder "Zugriff")
   - Klicke auf "Reset Root Password" (oder "Root-Passwort zurücksetzen")
   - **Neues Passwort wird generiert und angezeigt**
   - **WICHTIG: Sofort notieren!**

2. **Passwort kopieren:**
   - Das neue Passwort wird nur einmal angezeigt
   - Kopiere es sofort
   - Speichere es sicher (z.B. Passwort-Manager)

### Option 3: SSH-Key verwenden (empfohlen)

Statt Passwort kannst du auch einen SSH-Key verwenden:

1. **SSH-Key generieren** (falls noch nicht vorhanden):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **SSH-Key zum VPS hinzufügen:**
   - Im Hetzner Dashboard → Server → "Access"
   - Klicke auf "Add SSH Key" (oder "SSH-Key hinzufügen")
   - Füge deinen öffentlichen Key hinzu: `cat ~/.ssh/id_ed25519.pub`
   - Oder: Beim Server-Erstellen den Key auswählen

3. **Mit SSH-Key verbinden:**
   ```bash
   ssh root@37.27.12.97
   # Kein Passwort nötig!
   ```

---

## Schritt-für-Schritt: Passwort im Dashboard finden

### Visuelle Anleitung:

1. **Login:**
   ```
   https://console.hetzner.cloud/
   → Login mit deinem Account
   ```

2. **Server auswählen:**
   ```
   Dashboard → Servers → "ubuntu-4gb-hel1-3"
   ```

3. **Access-Tab:**
   ```
   Server-Details → Tab "Access" (oben)
   ```

4. **Passwort anzeigen:**
   ```
   Unter "Root Password"
   → Button "Show Password" klicken
   → Passwort wird angezeigt
   ```

---

## Nach dem Passwort finden

### SSH-Verbindung testen:

```bash
ssh root@37.27.12.97
# Passwort eingeben (wird nicht angezeigt beim Tippen)
```

### Oder SSH-Key kopieren:

```bash
# Mit Passwort (einmalig)
ssh-copy-id root@37.27.12.97

# Dann funktioniert es ohne Passwort
ssh root@37.27.12.97
```

---

## Sicherheitstipps

1. **SSH-Key statt Passwort verwenden** (sicherer)
2. **Passwort in Passwort-Manager speichern**
3. **Root-Login deaktivieren** (nach Setup)
4. **Firewall einrichten** (nur notwendige Ports)

---

## Troubleshooting

### "Permission denied"

- Prüfe ob Passwort korrekt ist
- Prüfe ob Server läuft
- Prüfe ob SSH aktiviert ist

### "Connection refused"

- Prüfe ob VPS gestartet ist
- Prüfe Firewall-Einstellungen
- Prüfe ob Port 22 offen ist

### Passwort funktioniert nicht

- Passwort zurücksetzen im Dashboard
- Prüfe ob Caps-Lock aktiv ist
- Prüfe ob richtiger User (root)





