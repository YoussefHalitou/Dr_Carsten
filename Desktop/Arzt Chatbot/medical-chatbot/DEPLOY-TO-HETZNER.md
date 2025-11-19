# 🚀 Deployment zu Hetzner Server - Schritt für Schritt

## Schritt 1: Server auf Hetzner erstellen

1. **Type:** CPX22 (€5.99/Monat) oder CPX32 (€10.49/Monat)
2. **Location:** Nürnberg oder Falkenstein
3. **Image:** Ubuntu 22.04 (OS Images)
4. **SSH Key:** Füge deinen SSH-Key hinzu:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDhyGue4lQEZMw4O2+ZPVxHEV/Pgk5GkwTlSmYaGUkG youssef_halitou@outlook.com
   ```
5. **Name:** `medical-chatbot`
6. **Create & Buy**

## Schritt 2: IP-Adresse notieren

Nach der Erstellung erhältst du eine IP-Adresse (z.B. `123.456.789.0`). **Notiere sie!**

## Schritt 3: Mit dem Server verbinden

```bash
# Verbinde dich mit dem Server
ssh root@DEINE_IP_ADRESSE

# Beispiel:
# ssh root@123.456.789.0
```

## Schritt 4: Setup-Skript ausführen

### Option A: Skript direkt auf Server kopieren

```bash
# Auf dem Server (nach SSH-Verbindung)
curl -fsSL https://raw.githubusercontent.com/YoussefHalitou/Dr_Carsten/main/medical-chatbot/setup-hetzner-server.sh -o setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

### Option B: Skript manuell hochladen

```bash
# Auf deinem lokalen Computer
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
scp setup-hetzner-server.sh root@DEINE_IP_ADRESSE:/root/

# Auf dem Server
ssh root@DEINE_IP_ADRESSE
chmod +x setup-hetzner-server.sh
./setup-hetzner-server.sh
```

## Schritt 5: .env Datei konfigurieren

```bash
# Auf dem Server
cd /opt/medical-chatbot/medical-chatbot
nano .env
```

**Inhalt:**
```env
OPENAI_API_KEY=dein-openai-api-key-hier
API_KEY=dein-starker-api-key-hier
CORS_ORIGINS=http://localhost:3000,http://DEINE_IP_ADRESSE
ENFORCE_HTTPS=false
ENVIRONMENT=production
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

## Schritt 6: App starten

```bash
# Auf dem Server
cd /opt/medical-chatbot/medical-chatbot
docker compose up -d --build
```

## Schritt 7: Status prüfen

```bash
# Container-Status
docker compose ps

# Logs ansehen
docker compose logs -f

# Backend Health-Check
curl http://localhost:8000/health

# Frontend testen
curl http://localhost:3000
```

## Schritt 8: App testen

Öffne in deinem Browser:
```
http://DEINE_IP_ADRESSE
```

**Fertig!** 🎉 Deine App läuft jetzt 24/7 auf dem Hetzner Server.

---

## Optional: Domain einrichten

### Schritt 1: Domain kaufen (z.B. bei Namecheap, ~10€/Jahr)

### Schritt 2: DNS-Einträge setzen

1. Gehe zu deinem Domain-Provider
2. Erstelle einen **A-Record**:
   - **Name:** @ (oder deine-domain.com)
   - **Type:** A
   - **Value:** DEINE_IP_ADRESSE
   - **TTL:** 3600

### Schritt 3: SSL-Zertifikat installieren

```bash
# Auf dem Server
apt install -y certbot python3-certbot-nginx

# SSL-Zertifikat erstellen
certbot --nginx -d deine-domain.com

# Automatische Erneuerung testen
certbot renew --dry-run
```

### Schritt 4: Nginx-Konfiguration für Domain aktualisieren

```bash
# Auf dem Server
nano /etc/nginx/sites-available/medical-chatbot
```

**Ändere:**
```nginx
server_name deine-domain.com;
```

```bash
# Nginx neu starten
nginx -t
systemctl restart nginx
```

**Fertig!** App läuft jetzt unter `https://deine-domain.com`

---

## Wartung

### Logs ansehen
```bash
docker compose logs -f
docker compose logs -f backend
docker compose logs -f frontend
```

### App neu starten
```bash
docker compose restart
docker compose restart backend
docker compose restart frontend
```

### Updates deployen
```bash
cd /opt/medical-chatbot/medical-chatbot
git pull
docker compose up -d --build
```

### Backup erstellen
```bash
# Datenbank-Backup
docker compose exec db pg_dump -U postgres medical_chatbot > backup_$(date +%Y%m%d).sql
```

---

## Troubleshooting

### Container startet nicht
```bash
docker compose logs
docker compose ps
```

### Port bereits belegt
```bash
netstat -tulpn | grep :8000
netstat -tulpn | grep :3000
```

### Nginx-Fehler
```bash
nginx -t
systemctl status nginx
journalctl -u nginx -f
```

---

## Kostenübersicht

- **VPS (CPX22):** €5.99/Monat
- **Domain (optional):** ~€10/Jahr
- **SSL (Let's Encrypt):** Kostenlos
- **Gesamt:** ~€6-7/Monat

---

## Hilfe

- **Setup-Probleme:** Prüfe die Logs: `docker compose logs`
- **Nginx-Probleme:** `nginx -t` und `systemctl status nginx`
- **Docker-Probleme:** `systemctl status docker`

