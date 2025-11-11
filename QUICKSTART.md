# Alpha AI - Schnellstart Guide

## 🚀 Ultra-Simple Setup mit main.bat

**Du brauchst nur EINE Datei zu starten!**

```bash
# Windows: Doppelklick auf:
main.bat

# Oder in der Kommandozeile:
main.bat
```

Das war's! Die `main.bat` managt alles automatisch:
- ✅ Installation aller Dependencies
- ✅ Virtuelle Umgebung erstellen
- ✅ Konfigurationsdatei erstellen
- ✅ Server-Checks
- ✅ Alpha AI starten

---

## 📋 Voraussetzungen

Nur **Python 3.10+** muss installiert sein:

1. Download: https://www.python.org/downloads/
2. Bei Installation: **"Add Python to PATH"** ankreuzen!
3. Fertig!

---

## 🎯 Erste Schritte

### 1. Starte main.bat

```bash
main.bat
```

### 2. API-Key eintragen

Beim ersten Start öffnet sich automatisch `character_config.yaml`.

Ersetze `gsk_YOUR_API_KEY_HERE` mit deinem echten Groq API-Key:

```yaml
GROQ_API_KEY: gsk_abc123...dein_echter_key
```

Speichern und Notepad schließen.

### 3. Fertig!

Alpha AI startet automatisch. Du siehst:

```
==============================================================
  Alpha AI Voice Assistant - Enhanced Edition
==============================================================

[1/3] Validating configuration...
✓ Configuration valid
✓ Model: llama-3.3-70b-versatile
✓ History limit: 50 messages

[2/3] Setting up directories...
✓ Directories ready

[3/3] Initializing Whisper model...
✓ Whisper model loaded

==============================================================
  Ready for conversation!
==============================================================
```

---

## 💬 Verwendung

### Gesprächsablauf

1. **Warte auf:** `🎤 [1] Waiting for your input...`
2. **Drücke ENTER** zum Starten der Aufnahme
3. **Sprich deine Frage**
4. **Drücke ENTER** zum Stoppen
5. **Warte auf Antwort** (Transkription → AI denkt → TTS)
6. **Höre die Antwort**
7. **Wiederhole** für nächste Frage

### Beenden

- **Ctrl+C** drücken für sauberen Shutdown

---

## ⚙️ Optionale Komponente: GPT-SoVITS

### Was ist GPT-SoVITS?

Text-to-Speech Server für natürliche Sprach-Ausgabe.

### Ist es notwendig?

**Nein!** Alpha AI funktioniert auch ohne TTS:
- ✅ Spracheingabe funktioniert
- ✅ AI-Antworten werden als Text angezeigt
- ⚠️ Keine Audio-Ausgabe

### Installation (Optional)

1. Download: https://github.com/RVC-Boss/GPT-SoVITS
2. Folge der Anleitung dort
3. Starte Server auf Port 9880
4. Starte `main.bat` erneut

---

## 🔧 Fehlerbehebung

### "Python ist nicht installiert"

```
[ERROR] Python ist nicht installiert!
```

**Lösung:**
1. Python installieren: https://www.python.org/downloads/
2. **"Add Python to PATH"** ankreuzen!
3. PC neu starten
4. `main.bat` erneut starten

---

### "FFmpeg nicht gefunden"

```
[WARNING] FFmpeg not found in PATH
```

**Lösung (einfachste Methode):**

```bash
# Mit winget (Windows 10/11):
winget install Gyan.FFmpeg

# Mit Chocolatey:
choco install ffmpeg
```

**Alternative:** Manuell von https://ffmpeg.org/download.html

---

### "Groq API timeout"

```
⚠️  Groq API timeout (attempt 1/3)
⏳ Retrying in 1 seconds...
```

**Ursachen:**
- Langsames Internet
- Groq Server überlastet
- API-Key falsch

**Was tut das System:**
- ✅ Automatische Retries (3 Versuche)
- ✅ Exponential Backoff (1s, 2s, 4s)
- ✅ Fallback-Nachricht bei Fehlschlag

**Du musst nichts tun!** System handhabt es automatisch.

---

### "No speech detected"

```
⚠️  No speech detected in recording. Please try again.
```

**Ursachen:**
- Zu leise gesprochen
- Mikrofon nicht als Standard eingestellt
- Hintergrundgeräusche zu laut

**Lösungen:**
1. Lauter sprechen
2. Näher ans Mikrofon
3. Windows-Einstellungen → Sound → Eingabegerät prüfen

---

### "GPT-SoVITS Server läuft nicht"

```
⚠️  TTS unavailable. (Is GPT-SoVITS server running?)
```

**Das ist KEIN Fehler!** Nur eine Info.

**Optionen:**
1. GPT-SoVITS installieren und starten (siehe oben)
2. Oder ohne TTS weitermachen (nur Text-Ausgabe)

---

## 🎉 Neue Features

### ✨ Voice Activity Detection (VAD)

Erkennt automatisch ob du sprichst:
- ✅ Warnt wenn keine Sprache erkannt
- ✅ Spart Zeit bei leeren Aufnahmen

### 🔊 Noise Reduction

Reduziert Hintergrundgeräusche automatisch:
- ✅ Bessere Transkriptionsqualität
- ✅ Funktioniert auch in lauter Umgebung

### ⏱️ Smart Retry

Bei API-Problemen:
- ✅ Automatische Wiederholung
- ✅ Keine manuellen Neustarts nötig

### 💾 Memory Management

Bei langen Gesprächen:
- ✅ Automatisches Trimmen alter Nachrichten
- ✅ Keine Speicherprobleme mehr
- ✅ Konfigurierbar in `character_config.yaml`

---

## ⚙️ Konfiguration (Optional)

### character_config.yaml

```yaml
# Groq API-Key (ERFORDERLICH)
GROQ_API_KEY: gsk_your_key_here

# Chat-Verlauf (Standard: chat_history.json)
history_file: chat_history.json

# AI-Model (Standard: llama-3.3-70b-versatile)
model: "llama-3.3-70b-versatile"

# Max. Nachrichten im Speicher (Standard: 50)
# Höher = mehr Kontext, aber mehr Speicher
max_history_messages: 50

# System-Prompt (Verhalten der AI)
presets:
  default:
    system_prompt: |
      You are Alpha, an intelligent AI assistant.
      Keep responses concise for voice conversation.

# TTS-Konfiguration (nur wenn GPT-SoVITS läuft)
sovits_ping_config:
  text_lang: en
  prompt_lang: en
  ref_audio_path: character_files/main_sample.wav
  prompt_text: This is a sample voice.
```

---

## 💡 Tipps für beste Ergebnisse

### Audio-Qualität

1. **Ruhige Umgebung:** Weniger Hintergrundgeräusche = bessere Erkennung
2. **Klare Aussprache:** Deutlich sprechen hilft
3. **Gutes Mikrofon:** USB-Mikrofon besser als Laptop-Mikrofon
4. **Richtige Distanz:** 10-30cm vom Mikrofon

### AI-Antworten

1. **Kurze Fragen:** Präzise Fragen → präzise Antworten
2. **Kontext:** AI erinnert sich an Gesprächsverlauf
3. **System-Prompt anpassen:** Ändere Persönlichkeit in Config

### Performance

1. **GPU nutzen:** Wenn vorhanden, deutlich schneller
2. **Chat-History begrenzen:** Bei langen Sessions `max_history_messages` reduzieren
3. **Whisper Model wählen:**
   - `tiny.en` - Schnell, weniger genau
   - `base.en` - Ausgewogen (Standard)
   - `small.en` - Langsamer, genauer

---

## 📊 Was passiert im Hintergrund?

```
┌─────────────────────────────────────────────────────────┐
│ 1. Du sprichst                                          │
│    ↓ (16 kHz Audio Recording)                           │
│ 2. Noise Reduction                                      │
│    ↓ (noisereduce Library)                              │
│ 3. Voice Activity Detection                             │
│    ↓ (Silero VAD)                                       │
│ 4. Faster-Whisper Transkription                         │
│    ↓ (Speech → Text)                                    │
│ 5. Groq llama-3.3-70b-versatile                         │
│    ↓ (+ Retry Logic)                                    │
│ 6. AI-Antwort generieren                                │
│    ↓                                                     │
│ 7. [Optional] GPT-SoVITS TTS                            │
│    ↓ (Text → Speech)                                    │
│ 8. Audio-Wiedergabe                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🆘 Support

### Probleme?

1. **GitHub Issues:** https://github.com/TheNickCoolst/Alpha-Ai/issues
2. **README:** Siehe README.md für Details
3. **IMPROVEMENTS.md:** Technische Details

### Logs

Bei Fehlern: Bitte den kompletten Output der Konsole kopieren und im Issue posten!

---

## 🎯 Zusammenfassung

### Was du brauchst
- ✅ Python 3.10+
- ✅ Groq API-Key
- ✅ Internet-Verbindung

### Was du tust
- ✅ `main.bat` starten
- ✅ API-Key eintragen
- ✅ Fertig!

### Was du bekommst
- ✅ Voice AI Assistant
- ✅ Automatische Installation
- ✅ Robuste Fehlerbehandlung
- ✅ Noise Reduction
- ✅ Smart Retries

**Viel Spaß mit Alpha AI! 🚀**
