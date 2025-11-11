# Alpha AI Voice Assistant

Alpha AI is an advanced voice-powered AI assistant that listens and remembers your conversations. It combines OpenAI's GPT, GPT-SoVITS voice synthesis, and Faster-Whisper ASR into a fully configurable conversational pipeline.

**Tested with Python 3.10+ on Windows 10+ and Linux Ubuntu**

## ✨ Features

- 💬 **LLM-based dialogue** using OpenAI API (configurable system prompts)
- 🧠 **Conversation memory** to keep context during interactions
- 🔊 **Voice generation** via GPT-SoVITS API
- 🎧 **Speech recognition** using Faster-Whisper
- 📁 Clean YAML-based config for personality configuration
- 🎯 Push-to-talk interface for natural interaction


## ⚙️ Configuration

All prompts and parameters are stored in `character_config.yaml`.

```yaml
OPENAI_API_KEY: sk-YOURAPIKEY
history_file: chat_history.json
model: "gpt-4o-mini"
presets:
  default:
    system_prompt: |
      You are Alpha, an intelligent AI assistant.
      You are helpful, knowledgeable, and conversational.

sovits_ping_config:
  text_lang: en
  prompt_lang: en
  ref_audio_path: character_files/main_sample.wav
  prompt_text: This is a sample voice for you to get started with.
```

You can define custom personalities by modifying the config file.


## 🛠️ Setup

### Quick Installation (Windows 11)

Alpha AI provides automated installation scripts for Windows 11:

**Option 1: PowerShell (Recommended)**
```powershell
# Right-click PowerShell and "Run as Administrator"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install_alpha_ai.ps1
```

**Option 2: Batch Script**
```cmd
install_alpha_ai.bat
```

Both scripts will:
- ✓ Check for Python 3.10+ (install via winget if missing)
- ✓ Check for FFmpeg (install via winget if missing)
- ✓ Create a virtual environment
- ✓ Install all Python dependencies
- ✓ Optionally install GPU support (CUDA)
- ✓ Set up project structure
- ✓ Create configuration template

### Quick Installation (Linux/Mac)

Run the installation script:

```bash
chmod +x install_alpha_ai.sh
./install_alpha_ai.sh
```

### Manual Installation

```bash
pip install uv
uv pip install -r requirements.txt
```

**For GPU support with Faster Whisper:**

* CUDA & cuDNN installed correctly (for Faster-Whisper GPU support)
* PyTorch with CUDA support: `pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu126`
* `ffmpeg` installed (for audio processing)


## 🧪 Usage

### 1. Launch the GPT-SoVITS API Server

Follow the [GPT-SoVITS documentation](https://github.com/RVC-Boss/GPT-SoVITS) to start the TTS server on port 9880.

### 2. Configure Your Settings

Edit `character_config.yaml` with your:
- OpenAI API key
- Voice sample path
- Desired personality/system prompt

### 3. Run the main script:

```bash
cd server
python main_chat.py
```

### How It Works:

1. Alpha listens to your voice via microphone (push-to-talk)
2. Transcribes your speech with Faster-Whisper
3. Sends the text to OpenAI GPT (with conversation history)
4. Generates an intelligent response
5. Synthesizes Alpha's voice using GPT-SoVITS
6. Plays the audio response back to you


## 🔧 Troubleshooting (Windows)

### PowerShell Script Won't Run
If you get an error about execution policies:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Python Not Found
Make sure Python is added to PATH during installation. You can verify with:
```cmd
python --version
```

If not found, reinstall Python from [python.org](https://www.python.org/downloads/) and check "Add Python to PATH"

### FFmpeg Not Found
Install FFmpeg using winget:
```cmd
winget install Gyan.FFmpeg
```

Or download manually from [ffmpeg.org](https://www.ffmpeg.org/download.html)

### Virtual Environment Issues
If activation fails, try:
```powershell
.\.venv\Scripts\Activate.ps1
```

Or for Command Prompt:
```cmd
.venv\Scripts\activate.bat
```

### GPU Support Not Working
Ensure you have:
- NVIDIA GPU with CUDA capability
- Latest NVIDIA drivers installed
- CUDA Toolkit installed from [NVIDIA Developer](https://developer.nvidia.com/cuda-downloads)

## 📌 TODO / Future Improvements

- [ ] GUI or web interface
- [ ] Continuous microphone input (VAD-based)
- [ ] Emotion or tone control in speech synthesis
- [ ] VRM/Live2D model frontend
- [ ] Multi-language support
- [ ] Voice activity detection for hands-free operation


## 🧑‍🎤 Credits

* Voice synthesis powered by [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS)
* ASR via [Faster-Whisper](https://github.com/SYSTRAN/faster-whisper)
* Language model via [OpenAI GPT](https://platform.openai.com)


## 📜 License

MIT — feel free to clone, modify, and build your own AI voice assistant.
