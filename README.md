# Ping Monitor Script 🚀

Ein intelligentes Shell-Script zur Überwachung der Netzwerklatenz mit automatischer Spike-Erkennung und Telegram-Benachrichtigungen.

## ✨ Features

- **Intelligente Spike-Erkennung**: Erkennt Latenz-Spikes basierend auf statistischen Abweichungen
- **Mehrsprachig**: Unterstützt Deutsch und Englisch
- **Telegram-Integration**: Automatische Benachrichtigungen bei Problemen
- **Detaillierte Analyse**: MTR-Traces und Ping-Statistiken bei Spikes
- **Kontinuierliche Überwachung**: Läuft dauerhaft im Hintergrund
- **Konfigurierbar**: Alle Parameter können angepasst werden

## 🔧 Installation

### Voraussetzungen

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install bc curl mtr-tiny

# CentOS/RHEL/Fedora  
sudo yum install bc curl mtr
# oder
sudo dnf install bc curl mtr

# Alpine Linux
apk add bc curl mtr
```

### Script herunterladen

```bash
curl -O https://raw.githubusercontent.com/[dein-username]/ping-monitor/main/ping-monitor.sh
chmod +x ping-monitor.sh
```

## ⚙️ Konfiguration

Öffne das Script und passe die Konfiguration an:

```bash
# Sprache / Language
LANGUAGE="de"          # "de" für Deutsch, "en" für Englisch

# Netzwerk-Konfiguration
SERVER="1.1.1.1"      # Zu überwachender Server
INTERVAL=60            # Sekunden zwischen Tests

# Spike-Erkennung
LOG_WINDOW=5           # Anzahl Pings für Durchschnittsberechnung
DEVIATION_FACTOR=2     # Faktor für Spike-Erkennung  
MIN_ABS_SPIKE=15       # Minimale ms für einen Spike

# Telegram-Bot Konfiguration
TG_BOT_TOKEN="DEIN_BOT_TOKEN"
TG_CHAT_ID="DEINE_CHAT_ID"
SEND_SILENT="yes"      # "yes" für stumme Nachrichten
```

### Telegram-Bot einrichten

1. **Bot erstellen**: Schreibe [@BotFather](https://t.me/botfather) auf Telegram
   ```
   /newbot
   [Bot-Name eingeben]
   [Bot-Username eingeben]
   ```

2. **Token kopieren**: Ersetze `TG_BOT_TOKEN` mit dem erhaltenen Token

3. **Chat-ID ermitteln**:
   ```bash
   # Bot zu Gruppe/Chat hinzufügen, dann:
   curl "https://api.telegram.org/bot[DEIN_TOKEN]/getUpdates"
   # Chat-ID aus der Antwort kopieren
   ```

## 🚀 Verwendung

### Einfacher Start
```bash
./ping-monitor.sh
```

### Als Daemon starten
```bash
# Im Hintergrund starten
nohup ./ping-monitor.sh > /var/log/ping-monitor.log 2>&1 &

# Mit systemd (empfohlen)
sudo cp ping-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ping-monitor
sudo systemctl start ping-monitor
```

### Beispiel systemd Service (`ping-monitor.service`)
```ini
[Unit]
Description=Ping Monitor
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/opt/ping-monitor/ping-monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## 📊 Output-Beispiele

### Normaler Betrieb
```
========================================
Neuer Test: 2024-01-15 14:30:00
----------------------------------------
OK: 1.1.1.1 12.5 ms
----------------------------------------
Warte 60 Sekunden bis zum nächsten Test...
```

### Spike erkannt
```
========================================  
Neuer Test: 2024-01-15 14:31:00
----------------------------------------
PING SPIKE: 1.1.1.1 156.2 ms (Vorheriger Durchschnitt: 12.8 ms)
Ping-Detailmessung (5x): 145.2 152.1 160.3 148.7 155.8
Ping-Statistik: Min: 145.2 ms, Max: 160.3 ms, Mittelwert: 152.42 ms
Starte MTR-Test zu 1.1.1.1 ...
[MTR-Output...]
```

### Telegram-Benachrichtigung
```
🚨 PING SPIKE zu 1.1.1.1!
Aktuell: 156.2 ms
Vorheriger Durchschnitt: 12.8 ms  
Detailmessung (5x): 145.2 152.1 160.3 148.7 155.8
Statistik: Min: 145.2 ms, Max: 160.3 ms, Mittelwert: 152.42 ms
2024-01-15 14:31:00
```

## 🔍 Funktionsweise

### Spike-Erkennung Algorithmus
1. **Gleitender Durchschnitt**: Berechnet aus den letzten N Ping-Zeiten
2. **Abweichungsfaktor**: Ping > (Durchschnitt × Faktor) = Spike
3. **Absoluter Mindest-Spike**: Zusätzliche Schwelle in ms
4. **Detailanalyse**: Bei Spike werden 5 weitere Pings + MTR ausgeführt

### Beispiel-Berechnung
```
Letzte Pings: [10, 12, 11, 13, 9] ms
Durchschnitt: 11 ms
Aktueller Ping: 25 ms

Spike-Check: 25 > (11 × 2) UND 25 > 15 = TRUE → SPIKE!
```

## 🛠️ Anpassungen

### Eigene Server überwachen
```bash
SERVER="google.com"     # Domain
SERVER="192.168.1.1"    # IP-Adresse  
SERVER="8.8.8.8"       # Öffentlicher DNS
```

### Sensitivität anpassen
```bash
# Weniger empfindlich
DEVIATION_FACTOR=3
MIN_ABS_SPIKE=50

# Empfindlicher  
DEVIATION_FACTOR=1.5
MIN_ABS_SPIKE=10
```

### Sprache ändern
```bash
LANGUAGE="en"    # Englisch
LANGUAGE="de"    # Deutsch
```

## 📋 Troubleshooting

### Script startet nicht
```bash
# Berechtigungen prüfen
ls -la ping-monitor.sh
chmod +x ping-monitor.sh

# Abhängigkeiten testen
which bc curl mtr ping
```

### Telegram funktioniert nicht
```bash
# Token testen
curl "https://api.telegram.org/bot[TOKEN]/getMe"

# Chat-ID prüfen  
curl "https://api.telegram.org/bot[TOKEN]/getUpdates"
```

### Hohe CPU-Last
```bash
# Intervall erhöhen
INTERVAL=300    # 5 Minuten statt 1 Minute
```

## 🤝 Contributing

Beiträge sind willkommen! Bitte:

1. Fork das Repository
2. Feature-Branch erstellen (`git checkout -b feature/AmazingFeature`)
3. Commits (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Pull Request öffnen

## 📝 Changelog

### v2.0.0
- ✨ Mehrsprachige Unterstützung (DE/EN)
- 🎨 Verbesserte Code-Struktur
- 📖 Erweiterte Dokumentation

### v1.0.0
- 🚀 Initiale Version
- 📊 Spike-Erkennung
- 📱 Telegram-Integration
- 🔍 MTR-Analyse

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei für Details.

## 👤 Autor

**[Alexander]**
- GitHub: [@revunix](https://github.com/revunix)
- Telegram: [@revunix]

## ⭐ Support

Wenn dir dieses Projekt hilft, gib ihm einen Stern! ⭐

Bei Problemen oder Fragen öffne ein [Issue](https://github.com/revunix/ping-monitor/issues).

---

<p align="center">
  Made with ❤️ for network monitoring
</p>
