# Python Version Fix - Quick Guide

## Problem
Du hast Python 3.13 installiert, aber Windows verwendet standardmäßig Python 3.14.

## Schnelle Lösung (Option 1): Python Launcher verwenden

Windows hat einen "Python Launcher" (`py`), der mehrere Python-Versionen verwalten kann.

### Testen ob Python 3.13 verfügbar ist:
```cmd
py -3.13 --version
```

### Alpha AI mit Python 3.13 starten:
```cmd
py -3.13 -m venv .venv
.venv\Scripts\activate.bat
py -3.13 -m pip install -r requirements.txt
```

## Alternative Lösung (Option 2): PATH anpassen

1. **Windows-Suche öffnen** → "Umgebungsvariablen" eingeben
2. **"Systemumgebungsvariablen bearbeiten"** öffnen
3. **"Umgebungsvariablen..."** Button klicken
4. Unter **"Benutzervariablen"** → **"Path"** auswählen → **"Bearbeiten"**
5. Den Eintrag für **Python 3.13** nach **oben** verschieben (über Python 3.14)
   - Meist: `C:\Users\<Benutzername>\AppData\Local\Programs\Python\Python313`
6. **OK** klicken und Terminal neu starten

## Alternative Lösung (Option 3): Python 3.14 deinstallieren

1. **Windows-Einstellungen** → **Apps** → **Installierte Apps**
2. Suche nach **"Python 3.14"**
3. Klicke auf **"Deinstallieren"**
4. Starte dein Terminal neu

## Prüfen welche Version jetzt aktiv ist:
```cmd
python --version
py -0p  # Zeigt alle installierten Python-Versionen
```

## Die neuen Scripts verwenden automatisch Python 3.13

Die aktualisierten `main.bat` und `install_alpha_ai.bat` Scripts suchen jetzt automatisch nach einer kompatiblen Python-Version (3.10-3.13) und verwenden sie, auch wenn Python 3.14 installiert ist.

**Einfach ausführen:**
```cmd
main.bat
```

Das Script findet automatisch Python 3.13!
