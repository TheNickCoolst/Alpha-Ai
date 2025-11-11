"""
Alpha AI TTS Module

Handles text-to-speech generation using GPT-SoVITS API.
Includes audio playback functionality.

Note: GPT-SoVITS server must be running on port 9880 before using this module.
"""
import requests
import time
import soundfile as sf
import sounddevice as sd
import yaml

# Load YAML config
with open('character_config.yaml', 'r') as f:
    char_config = yaml.safe_load(f)


def play_audio(path):
    """
    Play audio file using sounddevice.

    Args:
        path: Path to the audio file to play
    """
    data, samplerate = sf.read(path)
    sd.play(data, samplerate)
    sd.wait()  # Wait until playback is finished

def sovits_gen(in_text, output_wav_pth="output.wav"):
    """
    Generate speech audio from text using GPT-SoVITS API.

    Args:
        in_text: Text to convert to speech
        output_wav_pth: Path to save the generated audio file (default: "output.wav")

    Returns:
        Path to the generated audio file, or None if generation fails
    """
    url = "http://127.0.0.1:9880/tts"

    payload = {
        "text": in_text,
        "text_lang": char_config['sovits_ping_config']['text_lang'],
        "ref_audio_path": char_config['sovits_ping_config']['ref_audio_path'],
        "prompt_text": char_config['sovits_ping_config']['prompt_text'],
        "prompt_lang": char_config['sovits_ping_config']['prompt_lang']
    }

    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()

        print(f"✓ Generated speech for: {in_text[:50]}...")

        # Save the response audio
        with open(output_wav_pth, "wb") as f:
            f.write(response.content)

        return output_wav_pth

    except requests.exceptions.ConnectionError:
        print("✗ Error: Cannot connect to GPT-SoVITS server. Is it running on port 9880?")
        return None
    except requests.exceptions.Timeout:
        print("✗ Error: Request timed out. The text might be too long.")
        return None
    except Exception as e:
        print(f"✗ Error in sovits_gen: {e}")
        return None



if __name__ == "__main__":

    start_time = time.time()
    output_wav_pth1 = "output.wav"
    path_to_aud = sovits_gen("if you hear this, that means it is set up correctly", output_wav_pth1)
    
    end_time = time.time()
    elapsed_time = end_time - start_time

    print(f"Elapsed time: {elapsed_time:.4f} seconds")
    print(path_to_aud)


