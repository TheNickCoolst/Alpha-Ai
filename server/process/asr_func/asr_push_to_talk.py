"""
Alpha AI ASR (Automatic Speech Recognition) Module - ENHANCED

Handles voice recording and transcription using Faster-Whisper.
Implements push-to-talk functionality with:
- Voice Activity Detection (VAD) using Silero VAD
- Noise reduction for cleaner audio
- Automatic audio device detection
- Robust error handling
"""
import os
import numpy as np
import sounddevice as sd
import soundfile as sf
import torch
from faster_whisper import WhisperModel

# Optional imports with fallback
try:
    import noisereduce as nr
    NOISE_REDUCE_AVAILABLE = True
except ImportError:
    NOISE_REDUCE_AVAILABLE = False
    print("⚠️  noisereduce not available. Install with: pip install noisereduce")

try:
    from silero_vad import load_silero_vad, read_audio, get_speech_timestamps
    VAD_AVAILABLE = True
except ImportError:
    VAD_AVAILABLE = False
    print("⚠️  silero-vad not available. Install with: pip install silero-vad")


# Initialize VAD model (lazy loading)
_vad_model = None

def get_vad_model():
    """Lazy load VAD model to avoid startup delays."""
    global _vad_model
    if _vad_model is None and VAD_AVAILABLE:
        try:
            _vad_model = load_silero_vad()
        except Exception as e:
            print(f"⚠️  Could not load VAD model: {e}")
    return _vad_model


def get_default_audio_device():
    """
    Automatically detect the default audio input device.

    Returns:
        Device ID or None if no suitable device found
    """
    try:
        devices = sd.query_devices()
        default_input = sd.query_devices(kind='input')
        print(f"✓ Using audio device: {default_input['name']}")
        return None  # None means use system default
    except Exception as e:
        print(f"⚠️  Could not detect audio device: {e}")
        return None


def apply_noise_reduction(audio_data, samplerate):
    """
    Apply noise reduction to audio data.

    Args:
        audio_data: NumPy array of audio samples
        samplerate: Sample rate in Hz

    Returns:
        Noise-reduced audio data
    """
    if not NOISE_REDUCE_AVAILABLE:
        return audio_data

    try:
        # Apply stationary noise reduction
        reduced_audio = nr.reduce_noise(
            y=audio_data,
            sr=samplerate,
            stationary=True,
            prop_decrease=0.8
        )
        print("✓ Noise reduction applied")
        return reduced_audio
    except Exception as e:
        print(f"⚠️  Noise reduction failed: {e}")
        return audio_data


def detect_speech_segments(audio_file, vad_model):
    """
    Detect speech segments using Silero VAD.

    Args:
        audio_file: Path to audio file
        vad_model: Loaded VAD model

    Returns:
        List of speech timestamps or None if VAD fails
    """
    if not VAD_AVAILABLE or vad_model is None:
        return None

    try:
        wav = read_audio(audio_file)
        speech_timestamps = get_speech_timestamps(
            wav,
            vad_model,
            threshold=0.5,
            min_speech_duration_ms=250,
            min_silence_duration_ms=500
        )
        return speech_timestamps
    except Exception as e:
        print(f"⚠️  VAD detection failed: {e}")
        return None


def record_and_transcribe(model, output_file="recording.wav", samplerate=16000, max_duration=60):
    """
    Record audio using push-to-talk and transcribe it to text.
    Enhanced with noise reduction, VAD, and better error handling.

    Args:
        model: Faster-Whisper model instance
        output_file: Path to save the recording (default: "recording.wav")
        samplerate: Audio sample rate in Hz (default: 16000, optimal for Whisper)
        max_duration: Maximum recording duration in seconds (default: 60)

    Returns:
        Transcribed text from the audio recording
    """

    # Remove existing file
    if os.path.exists(output_file):
        os.remove(output_file)

    # Get default audio device
    device = get_default_audio_device()

    print("Press ENTER to start recording...")
    input()

    print(f"🔴 Recording... Press ENTER to stop (max {max_duration}s)")

    try:
        # Record audio
        recording = sd.rec(
            int(max_duration * samplerate),
            samplerate=samplerate,
            channels=1,
            dtype='float32',
            device=device
        )
        input()  # Wait for stop
        sd.stop()

        # Get actual recorded length
        recording = recording[:sd.get_stream().write_available]

    except Exception as e:
        print(f"❌ Recording error: {e}")
        print("⚠️  Using fallback recording method...")
        recording = sd.rec(int(max_duration * samplerate), samplerate=samplerate, channels=1, dtype='float32')
        input()
        sd.stop()

    print("⏹️  Processing audio...")

    # Convert to 1D array
    audio_data = recording.flatten()

    # Apply noise reduction if available
    if NOISE_REDUCE_AVAILABLE:
        audio_data = apply_noise_reduction(audio_data, samplerate)

    # Save the processed audio
    sf.write(output_file, audio_data, samplerate)

    # Apply VAD to detect if there's actual speech
    vad_model = get_vad_model()
    if vad_model is not None:
        speech_segments = detect_speech_segments(output_file, vad_model)
        if speech_segments is not None and len(speech_segments) == 0:
            print("⚠️  No speech detected in recording. Please try again.")
            return ""

    print("🎯 Transcribing...")

    try:
        # Transcribe with better parameters
        segments, info = model.transcribe(
            output_file,
            beam_size=5,
            vad_filter=True,  # Enable VAD filtering in Whisper
            vad_parameters=dict(
                threshold=0.5,
                min_speech_duration_ms=250,
                min_silence_duration_ms=500
            )
        )

        transcription = " ".join([segment.text for segment in segments])

        if transcription.strip():
            print(f"✓ Transcription: {transcription}")
        else:
            print("⚠️  No speech detected in transcription")

        return transcription.strip()

    except Exception as e:
        print(f"❌ Transcription error: {e}")
        return ""


# Example usage
if __name__ == "__main__":
    model = WhisperModel("base.en", device="cpu", compute_type="float32")
    result = record_and_transcribe(model)
    print(f"Got: '{result}'")
    