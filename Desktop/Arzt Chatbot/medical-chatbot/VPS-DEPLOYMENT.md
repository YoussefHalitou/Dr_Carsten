# VPS Deployment Guide - 24/7 Betrieb

## Übersicht

Diese Anleitung zeigt dir, wie du die Medical Chatbot App auf einem VPS (Virtual Private Server) deployst, damit sie 24/7 läuft.

---

## Schritt 1: VPS auswählen und einrichten

### VPS-Anbieter (Empfehlungen)

#### Option 1: Hetzner Cloud (Empfohlen, günstig)
- **Preis:** Ab 3,29€/Monat
- **Specs:** 1 vCPU, 2GB RAM, 20GB SSD
- **Standort:** Deutschland (Nürnberg, Falkenstein)
- **Link:** https://www.hetzner.com/cloud

#### Option 2: DigitalOcean
- **Preis:** Ab $4/Monat
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD
- **Standort:** Weltweit
- **Link:** https://www.digitalocean.com

#### Option 3: Linode
- **Preis:** Ab $5/Monat
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD
- **Link:** https://www.linode.com

### VPS erstellen

1. **Account erstellen** bei gewähltem Anbieter
2. **VPS erstellen:**
   - **OS:** Ubuntu 22.04 LTS (empfohlen)
   - **Size:** Minimum 2GB RAM, 20GB SSD
   - **Region:** Nahe zu deinem Standort
3. **SSH-Key hinzufügen** (empfohlen) oder Passwort setzen
4. **VPS starten** und IP-Adresse notieren

---

## Schritt 2: SSH-Zugriff einrichten

### Lokaler Computer (macOS/Linux)

```bash
# SSH-Key generieren (falls noch nicht vorhanden)
ssh-keygen -t ed25519 -C "your_email@example.com"

# SSH-Key zum VPS kopieren
ssh-copy-id root@DEINE_IP_ADRESSE

# Oder manuell:
cat ~/.ssh/id_ed25519.pub | ssh root@DEINE_IP_ADRESSE "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### VPS verbinden

```bash
# Verbinde dich zum VPS
ssh root@DEINE_IP_ADRESSE

# Oder mit Benutzer (falls nicht root):
ssh benutzer@DEINE_IP_ADRESSE
```

---

## Schritt 3: VPS vorbereiten

### System-Updates

```bash
# System aktualisieren
apt update && apt upgrade -y

# Basis-Tools installieren
apt install -y curl wget git vim ufw
```

### Firewall einrichten

```bash
# Firewall aktivieren
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Docker installieren

```bash
# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Docker Compose installieren
apt install -y docker-compose-plugin

# Docker-Service starten
systemctl start docker
systemctl enable docker

# Prüfen
docker --version
docker compose version
```

### Optional: Non-root User für Docker

```bash
# Benutzer erstellen (falls nicht vorhanden)
adduser deploy
usermod -aG docker deploy
usermod -aG sudo deploy

# Mit neuem Benutzer anmelden
su - deploy
```

---

## Schritt 4: App auf VPS deployen

### Option A: Von GitHub klonen (Empfohlen)

```bash
# App-Verzeichnis erstellen
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

# Repository klonen
git clone https://github.com/YOUSSEF_USERNAME/arztpraxis_chatbot.git .

# In medical-chatbot Verzeichnis wechseln
cd medical-chatbot
```

### Option B: Von lokalem Computer hochladen

```bash
# Auf lokalem Computer
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
tar -czf medical-chatbot.tar.gz .
scp medical-chatbot.tar.gz root@DEINE_IP_ADRESSE:/opt/

# Auf VPS
cd /opt
tar -xzf medical-chatbot.tar.gz
cd medical-chatbot
```

---

## Schritt 5: Environment-Variablen einrichten

### .env Datei erstellen

```bash
# .env Datei erstellen
nano .env
```

### Inhalt der .env Datei:

```env
# OpenAI API Key
OPENAI_API_KEY=dein-openai-api-key

# API Key für Authentifizierung
API_KEY=dein-starker-api-key-hier

# Datenbank URL (wird von docker-compose.yml gesetzt)
DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/medical_chatbot

# Port
PORT=8000

# CORS Origins (wird angepasst)
CORS_ORIGINS=http://localhost:3000,https://deine-domain.com

# HTTPS Enforcement
ENFORCE_HTTPS=true

# Debug Mode
DEBUG=false

# SQLAlchemy Echo
SQLALCHEMY_ECHO=false

# Environment
ENVIRONMENT=production
```

### Datei speichern (Ctrl+O, Enter, Ctrl+X)

---

## Schritt 6: Docker Compose anpassen

### docker-compose.yml für Produktion

```bash
# docker-compose.yml öffnen
nano docker-compose.yml
```

### Wichtige Anpassungen:

1. **CORS_ORIGINS:** Deine Domain hinzufügen
2. **ENFORCE_HTTPS:** Auf `true` setzen
3. **Ports:** Nur notwendige Ports exponieren
4. **Volumes:** Datenbank-Daten persistieren

### Beispiel (angepasst):

```yaml
services:
  db:
    image: postgres:16-alpine
    container_name: medical-chatbot-db
    environment:
      POSTGRES_DB: medical_chatbot
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network

  backend:
    build:
      context: ./backend
    container_name: medical-chatbot-backend
    depends_on:
      db:
        condition: service_healthy
    env_file:
      - .env
    environment:
      DATABASE_URL: postgresql+asyncpg://postgres:postgres@db:5432/medical_chatbot
      CORS_ORIGINS: ${CORS_ORIGINS:-http://localhost:3000}
      ENFORCE_HTTPS: 'true'
    ports:
      - '127.0.0.1:8000:8000'  # Nur lokal erreichbar
    restart: unless-stopped
    networks:
      - app-network

  frontend:
    build:
      context: ./frontend
      args:
        VITE_BACKEND_URL: ${VITE_BACKEND_URL:-http://localhost:8000}
        VITE_API_KEY: ${API_KEY:-change-me}
    container_name: medical-chatbot-frontend
    depends_on:
      - backend
    ports:
      - '127.0.0.1:3000:80'  # Nur lokal erreichbar
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

---

## Schritt 7: Nginx als Reverse Proxy einrichten

### Nginx installieren

```bash
apt install -y nginx
systemctl start nginx
systemctl enable nginx
```

### SSL-Zertifikat (Let's Encrypt)

```bash
# Certbot installieren
apt install -y certbot python3-certbot-nginx

# SSL-Zertifikat erstellen (nach Domain-Setup)
certbot --nginx -d deine-domain.com
```

### Nginx-Konfiguration

```bash
# Nginx-Konfiguration erstellen
nano /etc/nginx/sites-available/medical-chatbot
```

### Inhalt:

```nginx
server {
    listen 80;
    server_name deine-domain.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name deine-domain.com;

    # SSL-Zertifikate
    ssl_certificate /etc/letsencrypt/live/deine-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/deine-domain.com/privkey.pem;

    # SSL-Einstellungen
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

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

### Konfiguration aktivieren

```bash
# Symlink erstellen
ln -s /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/

# Test-Konfiguration
nginx -t

# Nginx neu starten
systemctl restart nginx
```

---

## Schritt 8: App starten

### Container bauen und starten

```bash
# In App-Verzeichnis
cd /opt/medical-chatbot

# Container bauen und starten
docker compose up -d --build

# Status prüfen
docker compose ps

# Logs ansehen
docker compose logs -f
```

### Prüfen ob alles läuft

```bash
# Container-Status
docker compose ps

# Backend Health-Check
curl http://localhost:8000/health

# Frontend
curl http://localhost:3000
```

---

## Schritt 9: Domain einrichten (Optional)

### DNS-Einträge

1. **A-Record erstellen:**
   - **Name:** @ (oder deine-domain.com)
   - **Type:** A
   - **Value:** DEINE_VPS_IP_ADRESSE
   - **TTL:** 3600

2. **Optional: WWW-Subdomain:**
   - **Name:** www
   - **Type:** A
   - **Value:** DEINE_VPS_IP_ADRESSE

### DNS prüfen

```bash
# DNS-Propagierung prüfen
dig deine-domain.com
nslookup deine-domain.com
```

---

## Schritt 10: Monitoring und Wartung

### Logs ansehen

```bash
# Alle Logs
docker compose logs -f

# Nur Backend
docker compose logs -f backend

# Nur Frontend
docker compose logs -f frontend
```

### Container neu starten

```bash
# Alle Container neu starten
docker compose restart

# Einzelnen Container neu starten
docker compose restart backend
```

### Updates deployen

```bash
# Code aktualisieren
cd /opt/medical-chatbot
git pull

# Container neu bauen und starten
docker compose up -d --build
```

### Backup erstellen

```bash
# Datenbank-Backup
docker compose exec db pg_dump -U postgres medical_chatbot > backup_$(date +%Y%m%d).sql

# Backup wiederherstellen
docker compose exec -T db psql -U postgres medical_chatbot < backup_20240101.sql
```

---

## Schritt 11: Automatische Neustarts

### Systemd Service erstellen

```bash
# Service-Datei erstellen
nano /etc/systemd/system/medical-chatbot.service
```

### Inhalt:

```ini
[Unit]
Description=Medical Chatbot Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/medical-chatbot
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### Service aktivieren

```bash
# Service aktivieren
systemctl daemon-reload
systemctl enable medical-chatbot.service
systemctl start medical-chatbot.service

# Status prüfen
systemctl status medical-chatbot.service
```

---

## Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
docker compose logs

# Container-Status
docker compose ps

# Docker-Service prüfen
systemctl status docker
```

### Port bereits belegt

```bash
# Ports prüfen
netstat -tulpn | grep :8000
netstat -tulpn | grep :3000

# Prozess beenden
kill -9 PID
```

### Datenbank-Verbindungsfehler

```bash
# Datenbank-Container prüfen
docker compose ps db
docker compose logs db

# Datenbank-Verbindung testen
docker compose exec db psql -U postgres -d medical_chatbot
```

---

## Sicherheit

### Firewall

```bash
# Nur notwendige Ports öffnen
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw enable
```

### SSH-Hardening

```bash
# SSH-Konfiguration
nano /etc/ssh/sshd_config

# Wichtige Einstellungen:
# PermitRootLogin no
# PasswordAuthentication no
# Port 22 (oder anderen Port)

# SSH neu starten
systemctl restart sshd
```

### Docker-Sicherheit

```bash
# Non-root User für Docker
adduser deploy
usermod -aG docker deploy

# Mit deploy-User arbeiten
su - deploy
```

---

## Kostenübersicht

### VPS (Hetzner)
- **VPS:** 3,29€/Monat
- **Domain:** ~10€/Jahr (optional)
- **Gesamt:** ~3-4€/Monat

### Alternative (Railway)
- **Starter Plan:** $5/Monat
- **Pro Plan:** $20/Monat
- **Gesamt:** $5-20/Monat

---

## Zusammenfassung

1. ✅ VPS erstellen (Ubuntu 22.04)
2. ✅ Docker installieren
3. ✅ App deployen
4. ✅ Environment-Variablen setzen
5. ✅ Nginx als Reverse Proxy
6. ✅ SSL-Zertifikat (Let's Encrypt)
7. ✅ Domain einrichten
8. ✅ App starten
9. ✅ Monitoring einrichten

**Fertig!** Die App läuft jetzt 24/7 auf dem VPS.

