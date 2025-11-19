# Quick Start: VPS Deployment

## Schnellstart-Anleitung (5 Minuten)

### Voraussetzungen

- ✅ VPS mit Ubuntu 22.04
- ✅ SSH-Zugriff zum VPS
- ✅ Domain (optional, für SSL)

---

## Schritt 1: VPS Setup (einmalig)

### Auf dem VPS ausführen:

```bash
# Script herunterladen (auf VPS)
wget https://raw.githubusercontent.com/YOUSSEF_USERNAME/arztpraxis_chatbot/main/setup-vps.sh
chmod +x setup-vps.sh
sudo ./setup-vps.sh
```

**Oder manuell:**

```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose installieren
sudo apt install -y docker-compose-plugin

# Firewall einrichten
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## Schritt 2: App deployen

### Option A: Mit Deployment-Script (empfohlen)

**Auf lokalem Computer:**

```bash
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
./deploy-to-vps.sh root@DEINE_VPS_IP
```

### Option B: Manuell

**Auf VPS:**

```bash
# App-Verzeichnis erstellen
sudo mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot

# Repository klonen
sudo git clone https://github.com/YOUSSEF_USERNAME/arztpraxis_chatbot.git .

# In medical-chatbot Verzeichnis wechseln
cd medical-chatbot

# .env Datei erstellen
sudo nano .env
```

**Inhalt der .env Datei:**

```env
OPENAI_API_KEY=dein-openai-api-key
API_KEY=dein-starker-api-key
CORS_ORIGINS=http://localhost:3000,https://deine-domain.com
ENFORCE_HTTPS=true
DEBUG=false
```

**Container starten:**

```bash
# Container bauen und starten
sudo docker compose up -d --build

# Status prüfen
sudo docker compose ps

# Logs ansehen
sudo docker compose logs -f
```

---

## Schritt 3: Nginx einrichten (optional, für Domain)

### Nginx installieren

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Nginx-Konfiguration

```bash
sudo nano /etc/nginx/sites-available/medical-chatbot
```

**Inhalt:**

```nginx
server {
    listen 80;
    server_name deine-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Konfiguration aktivieren

```bash
sudo ln -s /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Schritt 4: SSL-Zertifikat (optional)

```bash
# Certbot installieren
sudo apt install -y certbot python3-certbot-nginx

# SSL-Zertifikat erstellen
sudo certbot --nginx -d deine-domain.com

# Automatische Erneuerung testen
sudo certbot renew --dry-run
```

---

## Schritt 5: Prüfen

### Status prüfen

```bash
# Container-Status
sudo docker compose ps

# Backend Health-Check
curl http://localhost:8000/health

# Frontend
curl http://localhost:3000
```

### Öffentlich erreichbar

- **Mit Domain:** https://deine-domain.com
- **Ohne Domain:** http://DEINE_VPS_IP:3000

---

## Wartung

### Logs ansehen

```bash
# Alle Logs
sudo docker compose logs -f

# Nur Backend
sudo docker compose logs -f backend
```

### Container neu starten

```bash
sudo docker compose restart
```

### Updates deployen

```bash
cd /opt/medical-chatbot
sudo git pull
sudo docker compose up -d --build
```

---

## Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
sudo docker compose logs

# Container-Status
sudo docker compose ps
```

### Port bereits belegt

```bash
# Ports prüfen
sudo netstat -tulpn | grep :8000
sudo netstat -tulpn | grep :3000
```

### Firewall-Probleme

```bash
# Firewall-Status
sudo ufw status

# Ports öffnen
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

---

## Zusammenfassung

1. ✅ VPS Setup: `./setup-vps.sh`
2. ✅ App deployen: `./deploy-to-vps.sh user@vps-ip`
3. ✅ Nginx einrichten (optional)
4. ✅ SSL-Zertifikat (optional)
5. ✅ Fertig!

**Die App läuft jetzt 24/7 auf dem VPS!** 🎉

