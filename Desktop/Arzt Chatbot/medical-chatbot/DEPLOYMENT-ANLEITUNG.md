# 🚀 Deployment-Anleitung für Server 37.27.12.97

## Server-Informationen
- **IP-Adresse:** 37.27.12.97
- **Location:** Helsinki, Finnland
- **Type:** CPX22 (2 vCPU, 4GB RAM, 80GB Disk)

---

## Schritt 1: SSH-Verbindung herstellen

### Option A: Mit SSH-Key (empfohlen)

Falls dein SSH-Key noch nicht auf dem Server ist:

```bash
# SSH-Key zum Server kopieren
ssh-copy-id root@37.27.12.97

# Oder manuell:
cat ~/.ssh/id_ed25519.pub | ssh root@37.27.12.97 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Option B: Mit Passwort

```bash
# Verbinde dich mit dem Server
ssh root@37.27.12.97

# Du wirst nach dem Passwort gefragt (wurde dir per E-Mail gesendet)
```

---

## Schritt 2: Setup auf dem Server ausführen

Nach erfolgreicher SSH-Verbindung, führe diese Befehle **auf dem Server** aus:

### Automatisches Setup (empfohlen)

```bash
# Setup-Skript herunterladen und ausführen
curl -fsSL https://raw.githubusercontent.com/YoussefHalitou/Dr_Carsten/main/medical-chatbot/setup-hetzner-server.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

### Manuelles Setup (falls automatisch nicht funktioniert)

```bash
# 1. System aktualisieren
apt update && apt upgrade -y

# 2. Basis-Tools installieren
apt install -y curl wget git vim ufw

# 3. Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# 4. Docker Compose installieren
apt install -y docker-compose-plugin

# 5. Firewall einrichten
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable

# 6. App-Verzeichnis erstellen
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

# 7. Repository klonen
git clone https://github.com/YoussefHalitou/Dr_Carsten.git .
cd medical-chatbot

# 8. Nginx installieren
apt install -y nginx
systemctl start nginx
systemctl enable nginx
```

---

## Schritt 3: .env Datei erstellen

```bash
# Auf dem Server
cd /opt/medical-chatbot/medical-chatbot
nano .env
```

**Inhalt der .env Datei:**
```env
# OpenAI API Key
OPENAI_API_KEY=dein-openai-api-key-hier

# API Key für Authentifizierung
API_KEY=dein-starker-api-key-hier

# CORS Origins
CORS_ORIGINS=http://localhost:3000,http://37.27.12.97

# HTTPS Enforcement
ENFORCE_HTTPS=false

# Environment
ENVIRONMENT=production
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Schritt 4: Nginx konfigurieren

```bash
# Auf dem Server
nano /etc/nginx/sites-available/medical-chatbot
```

**Inhalt:**
```nginx
server {
    listen 80;
    server_name 37.27.12.97;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket Support
    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Speichern:** `Ctrl+O`, `Enter`, `Ctrl+X`

```bash
# Nginx-Konfiguration aktivieren
ln -sf /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
```

---

## Schritt 5: App starten

```bash
# Auf dem Server
cd /opt/medical-chatbot/medical-chatbot
docker compose up -d --build
```

---

## Schritt 6: Status prüfen

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

---

## ✅ Fertig!

Deine App ist jetzt erreichbar unter:
```
http://37.27.12.97
```

---

## Nützliche Befehle

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

## Optional: Domain einrichten

Falls du eine Domain hast:

1. **DNS A-Record erstellen:**
   - Name: @ (oder deine-domain.com)
   - Type: A
   - Value: 37.27.12.97

2. **SSL-Zertifikat installieren:**
   ```bash
   apt install -y certbot python3-certbot-nginx
   certbot --nginx -d deine-domain.com
   ```

3. **Nginx-Konfiguration aktualisieren:**
   ```bash
   nano /etc/nginx/sites-available/medical-chatbot
   # server_name deine-domain.com;
   nginx -t
   systemctl restart nginx
   ```

