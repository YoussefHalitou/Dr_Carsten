# Hosting-Guide: Permanente URL für Medical Chatbot

## 🎯 Übersicht

Dieser Guide zeigt dir verschiedene Optionen, um deine Medical Chatbot App mit einer **permanenten URL** zu hosten (keine zeitlich begrenzten ngrok-URLs).

---

## 🚀 Option 1: VPS (Virtual Private Server) - **EMPFOHLEN**

### Vorteile
- ✅ **Permanente URL** (Domain oder IP)
- ✅ **Vollständige Kontrolle**
- ✅ **24/7 Betrieb**
- ✅ **Günstig** (ab 3-4€/Monat)
- ✅ **SSL-Zertifikat** (Let's Encrypt, kostenlos)
- ✅ **Skalierbar**

### Anbieter

#### Hetzner Cloud (Deutschland, günstig)
- **Preis:** Ab 3,29€/Monat
- **Specs:** 1 vCPU, 2GB RAM, 20GB SSD
- **Link:** https://www.hetzner.com/cloud
- **Standort:** Nürnberg, Falkenstein

#### DigitalOcean
- **Preis:** Ab $4/Monat
- **Specs:** 1 vCPU, 1GB RAM, 25GB SSD
- **Link:** https://www.digitalocean.com

#### Contabo (sehr günstig)
- **Preis:** Ab 3,99€/Monat
- **Specs:** 2 vCPU, 4GB RAM, 50GB SSD
- **Link:** https://www.contabo.com

### Schnellstart VPS

#### Schritt 1: VPS erstellen
1. Account bei Hetzner/DigitalOcean erstellen
2. VPS erstellen:
   - **OS:** Ubuntu 22.04 LTS
   - **Size:** Minimum 2GB RAM
   - **Region:** Nahe zu dir
3. IP-Adresse notieren

#### Schritt 2: VPS vorbereiten (auf dem Server)

```bash
# SSH-Verbindung
ssh root@DEINE_IP_ADRESSE

# System aktualisieren
apt update && apt upgrade -y

# Docker installieren
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Docker Compose installieren
apt install -y docker-compose-plugin

# Firewall einrichten
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
```

#### Schritt 3: App deployen

**Option A: Von GitHub klonen (empfohlen)**

```bash
# Auf dem VPS
mkdir -p /opt/medical-chatbot
cd /opt/medical-chatbot
git clone https://github.com/YoussefHalitou/Dr_Carsten.git .
cd medical-chatbot
```

**Option B: Mit Deployment-Skript (vom lokalen Computer)**

```bash
# Auf deinem lokalen Computer
cd "/Users/youssef/Desktop/Arzt Chatbot/medical-chatbot"
./deploy-to-vps.sh root@DEINE_IP_ADRESSE
```

#### Schritt 4: Environment-Variablen setzen

```bash
# Auf dem VPS
cd /opt/medical-chatbot/medical-chatbot
nano .env
```

**Inhalt:**
```env
OPENAI_API_KEY=dein-openai-api-key
API_KEY=dein-starker-api-key
CORS_ORIGINS=https://deine-domain.com,http://DEINE_IP_ADRESSE
ENFORCE_HTTPS=true
```

#### Schritt 5: Nginx + SSL einrichten

```bash
# Nginx installieren
apt install -y nginx certbot python3-certbot-nginx

# Nginx-Konfiguration erstellen
nano /etc/nginx/sites-available/medical-chatbot
```

**Nginx-Konfiguration:**
```nginx
server {
    listen 80;
    server_name DEINE_IP_ADRESSE oder deine-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Konfiguration aktivieren
ln -s /etc/nginx/sites-available/medical-chatbot /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

#### Schritt 6: App starten

```bash
cd /opt/medical-chatbot/medical-chatbot
docker compose up -d --build
```

#### Schritt 7: SSL-Zertifikat (wenn Domain vorhanden)

```bash
certbot --nginx -d deine-domain.com
```

**Fertig!** Deine App ist jetzt unter `http://DEINE_IP_ADRESSE` oder `https://deine-domain.com` erreichbar.

**Kosten:** ~3-4€/Monat + Domain (optional, ~10€/Jahr)

---

## ☁️ Option 2: Cloud-Plattformen (einfacher, aber teurer)

### Railway.app

**Vorteile:**
- ✅ Sehr einfach zu deployen
- ✅ Automatisches SSL
- ✅ GitHub-Integration
- ✅ Automatische Deployments

**Nachteile:**
- ❌ Teurer (~$5-20/Monat)
- ❌ Weniger Kontrolle

**Schnellstart:**
1. Gehe zu https://railway.app
2. "New Project" → "Deploy from GitHub repo"
3. Wähle dein Repository
4. Environment-Variablen setzen
5. Fertig!

**Kosten:** $5-20/Monat

### Render.com

**Vorteile:**
- ✅ Kostenloser Plan verfügbar
- ✅ Automatisches SSL
- ✅ GitHub-Integration

**Nachteile:**
- ❌ Free Plan: App schläft nach Inaktivität
- ❌ Langsamere Starts

**Schnellstart:**
1. Gehe zu https://render.com
2. "New" → "Web Service"
3. GitHub-Repository verbinden
4. Environment-Variablen setzen
5. Deploy!

**Kosten:** Free (mit Einschränkungen) oder $7+/Monat

### Fly.io

**Vorteile:**
- ✅ Sehr schnell
- ✅ Globale Edge-Netzwerke
- ✅ Gute Docker-Unterstützung

**Nachteile:**
- ❌ Etwas komplexer Setup

**Kosten:** Free (mit Limits) oder Pay-as-you-go

---

## 🎯 Option 3: Domain + Cloudflare Tunnel (kostenlos)

Wenn du bereits einen VPS oder Server hast, kannst du Cloudflare Tunnel verwenden:

### Vorteile
- ✅ **Kostenlos**
- ✅ **Permanente URL** (über Domain)
- ✅ **SSL automatisch**
- ✅ **DDoS-Schutz**

### Setup

```bash
# Cloudflared installieren
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Tunnel erstellen
cloudflared tunnel create medical-chatbot

# Tunnel konfigurieren
cloudflared tunnel route dns medical-chatbot deine-domain.com

# Tunnel starten
cloudflared tunnel run medical-chatbot
```

**Kosten:** Kostenlos (nur Domain nötig, ~10€/Jahr)

---

## 📊 Vergleich

| Option | Kosten/Monat | Schwierigkeit | Permanente URL | SSL |
|--------|--------------|---------------|----------------|-----|
| **VPS (Hetzner)** | 3-4€ | Mittel | ✅ | ✅ |
| **Railway** | $5-20 | Einfach | ✅ | ✅ |
| **Render** | Free/$7+ | Einfach | ✅ | ✅ |
| **Cloudflare Tunnel** | Free | Mittel | ✅ | ✅ |

---

## 🎯 Empfehlung

### Für Produktion: **VPS (Hetzner)**
- Günstig
- Vollständige Kontrolle
- Professionell
- Skalierbar

### Für schnelles Testen: **Railway**
- Sehr einfach
- Schnell deployt
- Automatisches SSL

### Für kostenlosen Betrieb: **Cloudflare Tunnel**
- Kostenlos
- Permanente URL
- Professionell

---

## 🚀 Schnellstart: VPS mit Hetzner

1. **VPS erstellen:** https://www.hetzner.com/cloud
   - Ubuntu 22.04
   - 2GB RAM Minimum

2. **SSH-Verbindung:**
   ```bash
   ssh root@DEINE_IP
   ```

3. **Docker installieren:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
   apt install -y docker-compose-plugin
   ```

4. **App klonen:**
   ```bash
   mkdir -p /opt/medical-chatbot && cd /opt/medical-chatbot
   git clone https://github.com/YoussefHalitou/Dr_Carsten.git .
   cd medical-chatbot
   ```

5. **.env erstellen:**
   ```bash
   nano .env
   # OPENAI_API_KEY=...
   # API_KEY=...
   ```

6. **Nginx installieren:**
   ```bash
   apt install -y nginx
   ```

7. **App starten:**
   ```bash
   docker compose up -d --build
   ```

8. **Nginx konfigurieren** (siehe oben)

**Fertig!** App läuft unter `http://DEINE_IP`

---

## 📝 Nächste Schritte

1. **Domain kaufen** (optional, z.B. bei Namecheap, ~10€/Jahr)
2. **DNS einrichten** (A-Record auf VPS-IP)
3. **SSL-Zertifikat** (Let's Encrypt, kostenlos)
4. **Monitoring einrichten** (optional)

---

## 🆘 Hilfe

- **VPS-Probleme:** Siehe `VPS-DEPLOYMENT.md`
- **Deployment-Skript:** `./deploy-to-vps.sh`
- **Docker-Probleme:** `docker compose logs`

