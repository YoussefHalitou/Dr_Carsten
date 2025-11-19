# SSH-Zugriff für Hetzner VPS einrichten

## Dein VPS

- **IP-Adresse:** 37.27.12.97
- **Provider:** Hetzner (Helsinki)
- **Standard-User:** root

---

## Option 1: SSH-Key einrichten (Empfohlen)

### Schritt 1: SSH-Key generieren (falls noch nicht vorhanden)

```bash
# Prüfe ob SSH-Key existiert
ls -la ~/.ssh/id_ed25519.pub

# Falls nicht vorhanden, generiere einen neuen
ssh-keygen -t ed25519 -C "your_email@example.com"
# Enter drücken für Standard-Pfad
# Optional: Passphrase setzen
```

### Schritt 2: SSH-Key zum VPS kopieren

**Methode A: Mit ssh-copy-id (einfach)**

```bash
# Benötigt zunächst Passwort-Zugriff
ssh-copy-id root@37.27.12.97
```

**Methode B: Manuell**

```bash
# Zeige deinen öffentlichen Key
cat ~/.ssh/id_ed25519.pub

# Kopiere den Output, dann auf VPS:
ssh root@37.27.12.97
# Auf VPS:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "DEIN_PUBLIC_KEY_HIER" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

### Schritt 3: Verbindung testen

```bash
ssh root@37.27.12.97
# Sollte jetzt ohne Passwort funktionieren
```

---

## Option 2: Passwort-Zugriff verwenden

### Schritt 1: Passwort vom Hetzner Dashboard

1. Gehe zu Hetzner Cloud Console
2. Öffne deinen Server
3. Unter "Access" → "Reset Root Password"
4. Passwort kopieren oder neu setzen

### Schritt 2: Verbindung testen

```bash
ssh root@37.27.12.97
# Passwort eingeben (wird nicht angezeigt)
```

---

## Option 3: Hetzner Cloud Console (Web-SSH)

1. Gehe zu Hetzner Cloud Console
2. Öffne deinen Server
3. Klicke auf "Console" (Web-SSH)
4. Du bist direkt im VPS

---

## Troubleshooting

### "Permission denied (publickey,password)"

**Lösung:**
- Prüfe ob SSH-Key korrekt kopiert wurde
- Prüfe ob Passwort korrekt ist
- Prüfe ob VPS läuft

### "Connection refused"

**Lösung:**
- Prüfe ob VPS gestartet ist
- Prüfe Firewall-Einstellungen
- Prüfe ob Port 22 offen ist

### "Host key verification failed"

**Lösung:**
```bash
# Entferne alte Einträge
ssh-keygen -R 37.27.12.97

# Oder manuell aus known_hosts entfernen
nano ~/.ssh/known_hosts
```

---

## Nach erfolgreicher SSH-Verbindung

Sobald SSH funktioniert, kannst du das Deployment starten:

```bash
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
./deploy-to-hetzner.sh
```

