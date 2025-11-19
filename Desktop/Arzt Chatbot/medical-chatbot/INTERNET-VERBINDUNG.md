# Internet-Verbindung: Was du wissen musst

## Kurze Antwort

**Ja, der Computer muss die ganze Zeit ans Internet verbunden sein**, wenn die App öffentlich erreichbar sein soll.

---

## Wie funktioniert es?

### Cloudflare Tunnel benötigt:

1. **Aktive Internetverbindung**
   - Der Tunnel verbindet deinen lokalen Computer mit Cloudflare
   - Ohne Internet → Tunnel bricht ab → URLs nicht erreichbar

2. **Laufender Computer**
   - Container müssen laufen (Frontend, Backend, DB)
   - Tunnels müssen laufen (cloudflared)
   - Computer aus → Alles gestoppt → URLs nicht erreichbar

3. **Stabile Verbindung**
   - Bei kurzen Unterbrechungen: Tunnels verbinden sich automatisch wieder
   - Bei längeren Ausfällen: Tunnels müssen neu gestartet werden

---

## Was passiert bei Unterbrechungen?

### Kurze Unterbrechung (< 1 Minute)

✅ **Automatische Wiederherstellung:**
- Cloudflare Tunnel versucht automatisch, sich wieder zu verbinden
- Container laufen weiter
- URLs werden wieder erreichbar (nach kurzer Zeit)

### Längere Unterbrechung (> 1 Minute)

⚠️ **Mögliche Probleme:**
- Tunnels müssen möglicherweise neu gestartet werden
- URLs können sich ändern (bei Neustart)
- Container laufen weiter, aber sind nicht erreichbar

### Computer ausgeschaltet

❌ **Kompletter Ausfall:**
- Alle Container gestoppt
- Alle Tunnels gestoppt
- URLs nicht erreichbar
- Datenbank-Daten bleiben erhalten (in Docker Volumes)

---

## Praktische Beispiele

### Szenario 1: WLAN unterbrochen

```
1. WLAN geht kurz weg (30 Sekunden)
   → Tunnels versuchen automatisch, sich wieder zu verbinden
   → Nach Wiederverbindung: Alles funktioniert wieder
   ✅ Keine Aktion erforderlich
```

### Szenario 2: Internet komplett weg (5 Minuten)

```
1. Internet weg
   → Tunnels verlieren Verbindung
   → URLs nicht erreichbar
   
2. Internet zurück
   → Tunnels verbinden sich automatisch wieder
   → URLs werden wieder erreichbar
   ✅ Meist automatisch, manchmal Neustart nötig
```

### Szenario 3: Computer in Sleep-Modus

```
1. Computer geht in Sleep-Modus
   → Alle Prozesse pausieren
   → Tunnels gestoppt
   → URLs nicht erreichbar
   
2. Computer aufwachen
   → Container laufen weiter (wenn vorher gestartet)
   → Tunnels müssen neu gestartet werden
   ⚠️  Aktion erforderlich: ./start-cloudflare-tunnels.sh
```

### Szenario 4: Computer ausgeschaltet

```
1. Computer aus
   → Alles gestoppt
   → URLs nicht erreichbar
   
2. Computer an
   → Alles muss neu gestartet werden:
     - docker compose up -d
     - ./start-cloudflare-tunnels.sh
   ⚠️  Aktion erforderlich
```

---

## Lösungen für 24/7 Betrieb

### Option 1: VPS (Virtual Private Server) ✅ Empfohlen

**Vorteile:**
- ✅ Läuft 24/7 (auch wenn dein Computer aus ist)
- ✅ Stabile Internetverbindung
- ✅ Feste IP-Adresse
- ✅ Professioneller Betrieb

**Anbieter:**
- **Hetzner** (günstig, ab ~3€/Monat)
- **DigitalOcean** (einfach, ab $4/Monat)
- **Linode** (zuverlässig, ab $5/Monat)
- **AWS** (skalierbar, Pay-as-you-go)
- **Railway** (einfach, bereits verwendet)

**Kosten:** Ab ~3-5€/Monat

### Option 2: Cloud-Hosting (Railway, Render, etc.)

**Vorteile:**
- ✅ Läuft 24/7 in der Cloud
- ✅ Automatische Deployments
- ✅ Einfache Verwaltung
- ✅ Kostenloser Plan verfügbar (mit Limits)

**Nachteile:**
- ⚠️  Kostenloser Plan: App schläft nach Inaktivität
- ⚠️  Paid Plan nötig für 24/7 Betrieb

### Option 3: Raspberry Pi (zu Hause)

**Vorteile:**
- ✅ Günstig (~50€ einmalig)
- ✅ Läuft 24/7 (wenn eingeschaltet)
- ✅ Kontrolle über Hardware

**Nachteile:**
- ⚠️  Benötigt stabile Internetverbindung zu Hause
- ⚠️  Stromkosten
- ⚠️  Router-Konfiguration nötig (Port-Forwarding)

### Option 4: Laptop immer an lassen

**Vorteile:**
- ✅ Einfach (nichts Neues kaufen)
- ✅ Sofort verfügbar

**Nachteile:**
- ❌ Stromkosten
- ❌ Computer muss immer an sein
- ❌ WLAN/Internet muss stabil sein
- ❌ Nicht professionell

---

## Empfehlung

### Für Entwicklung/Testen:
✅ **Lokaler Computer mit Cloudflare Tunnel**
- Kostenlos
- Einfach zu testen
- Perfekt für Demos

### Für Produktion/24/7 Betrieb:
✅ **VPS oder Cloud-Hosting**
- Professionell
- Stabil
- Zuverlässig

---

## Was du jetzt machen kannst

### Aktuelle Situation (Lokaler Computer):

1. **App ist erreichbar**, solange:
   - ✅ Computer an ist
   - ✅ Internet verbunden ist
   - ✅ Container laufen
   - ✅ Tunnels laufen

2. **App ist nicht erreichbar**, wenn:
   - ❌ Computer aus ist
   - ❌ Internet weg ist
   - ❌ Container gestoppt sind
   - ❌ Tunnels gestoppt sind

### Für 24/7 Betrieb:

1. **VPS mieten** (empfohlen)
2. **App auf VPS deployen**
3. **Docker auf VPS installieren**
4. **App starten**
5. **Fertig!** (läuft 24/7)

---

## Zusammenfassung

| Szenario | Internet nötig? | Computer an? | App erreichbar? |
|----------|----------------|--------------|-----------------|
| Normale Nutzung | ✅ Ja | ✅ Ja | ✅ Ja |
| Kurze Unterbrechung | ⚠️  Weg | ✅ Ja | ⚠️  Temporär weg |
| Längere Unterbrechung | ❌ Weg | ✅ Ja | ❌ Nein |
| Computer aus | ❓ Egal | ❌ Nein | ❌ Nein |
| Sleep-Modus | ❓ Egal | ⚠️  Sleep | ❌ Nein |

**Für 24/7 Betrieb:** VPS oder Cloud-Hosting verwenden!

