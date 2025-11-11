"""
Alpha AI Main Chat Loop - ENHANCED

Orchestrates the complete voice conversation pipeline:
1. Validate configuration
2. Record user voice (push-to-talk with VAD)
3. Transcribe speech to text (Faster-Whisper with noise reduction)
4. Generate AI response (OpenAI GPT with timeout handling)
5. Synthesize response to speech (GPT-SoVITS)
6. Play audio back to user

Requirements:
- GPT-SoVITS server running on port 9880
- Valid OpenAI API key in character_config.yaml
- Working microphone for input

Enhancements:
- Configuration validation on startup
- Better error handling and recovery
- Graceful degradation when services unavailable
- Memory management for long conversations
"""
from faster_whisper import WhisperModel
from process.asr_func.asr_push_to_talk import record_and_transcribe
from process.llm_funcs.llm_scr import llm_response
from process.tts_func.sovits_ping import sovits_gen, play_audio
from config_validator import validate_config, print_validation_errors
from pathlib import Path
import os
import sys
import time
import uuid
import soundfile as sf


def get_wav_duration(path):
    """
    Calculate the duration of a WAV audio file.

    Args:
        path: Path to the WAV file

    Returns:
        Duration in seconds
    """
    try:
        with sf.SoundFile(path) as f:
            return len(f) / f.samplerate
    except Exception as e:
        print(f"⚠️  Error calculating audio duration: {e}")
        return 0


def cleanup_audio_files(audio_dir="audio", keep_recent=0):
    """
    Clean up temporary audio files.

    Args:
        audio_dir: Directory containing audio files
        keep_recent: Number of recent files to keep (0 = delete all)
    """
    try:
        audio_path = Path(audio_dir)
        if not audio_path.exists():
            return

        wav_files = sorted(audio_path.glob("*.wav"), key=lambda x: x.stat().st_mtime)

        # Delete old files, keep recent ones
        files_to_delete = wav_files[:-keep_recent] if keep_recent > 0 else wav_files

        for fp in files_to_delete:
            try:
                fp.unlink()
            except Exception as e:
                print(f"⚠️  Could not delete {fp}: {e}")
    except Exception as e:
        print(f"⚠️  Error during cleanup: {e}")


def initialize_system():
    """
    Initialize the Alpha AI system with validation and setup.

    Returns:
        WhisperModel instance or None on failure
    """
    print('\n' + '='*60)
    print('  Alpha AI Voice Assistant - Enhanced Edition')
    print('='*60 + '\n')

    # Step 1: Validate configuration
    print('[1/3] Validating configuration...')
    is_valid, config, errors = validate_config()

    if not is_valid:
        print_validation_errors(errors)
        return None

    print(f'✓ Configuration valid')
    print(f'✓ Model: {config["model"]}')
    print(f'✓ History limit: {config.get("max_history_messages", 50)} messages\n')

    # Step 2: Create necessary directories
    print('[2/3] Setting up directories...')
    Path("audio").mkdir(parents=True, exist_ok=True)
    Path("character_files").mkdir(parents=True, exist_ok=True)
    print('✓ Directories ready\n')

    # Step 3: Initialize Whisper model
    print('[3/3] Initializing Whisper model...')
    try:
        whisper_model = WhisperModel(
            "base.en",
            device="cpu",
            compute_type="float32"
        )
        print('✓ Whisper model loaded\n')
        return whisper_model
    except Exception as e:
        print(f'❌ Error loading Whisper model: {e}')
        return None


def main():
    """Main conversation loop with enhanced error handling."""

    # Initialize system
    whisper_model = initialize_system()

    if whisper_model is None:
        print("\n❌ System initialization failed. Please fix errors and try again.")
        input("\nPress ENTER to exit...")
        sys.exit(1)

    print('='*60)
    print('  Ready for conversation!')
    print('='*60)
    print('\nTips:')
    print('  - Press Ctrl+C to exit at any time')
    print('  - Speak clearly after starting recording')
    print('  - Background noise will be automatically reduced\n')
    print('='*60 + '\n')

    conversation_count = 0

    try:
        while True:
            conversation_count += 1

            # Step 1: Record user input
            conversation_recording = Path("audio") / "conversation.wav"

            print(f"🎤 [{conversation_count}] Waiting for your input...")

            try:
                user_spoken_text = record_and_transcribe(whisper_model, conversation_recording)
            except KeyboardInterrupt:
                raise  # Re-raise to handle in outer try-except
            except Exception as e:
                print(f"❌ Recording error: {e}")
                print("⚠️  Skipping this turn. Try again.\n")
                continue

            if not user_spoken_text or user_spoken_text.strip() == "":
                print("⚠️  No speech detected. Try again.\n")
                continue

            print(f"💬 You: {user_spoken_text}")

            # Step 2: Get LLM response
            print("🤔 Alpha is thinking...")

            try:
                llm_output = llm_response(user_spoken_text)
            except KeyboardInterrupt:
                raise
            except Exception as e:
                print(f"❌ Error getting AI response: {e}")
                llm_output = "I encountered an error processing your request. Please try again."

            print(f"🤖 Alpha: {llm_output}")

            # Step 3: Generate unique filename for TTS output
            uid = uuid.uuid4().hex
            filename = f"output_{uid}.wav"
            output_wav_path = Path("audio") / filename

            # Step 4: Generate and play audio response
            print("🔊 Generating speech...")

            try:
                gen_aud_path = sovits_gen(llm_output, output_wav_path)

                if gen_aud_path and Path(gen_aud_path).exists():
                    print("▶️  Playing response...")
                    play_audio(output_wav_path)
                else:
                    print("⚠️  TTS unavailable. (Is GPT-SoVITS server running?)")
            except KeyboardInterrupt:
                raise
            except Exception as e:
                print(f"⚠️  TTS error: {e}")

            # Step 5: Cleanup temporary audio files (keep last 2)
            cleanup_audio_files(keep_recent=2)

            print("\n" + "="*60 + "\n")

    except KeyboardInterrupt:
        print("\n\n" + "="*60)
        print("  Shutting down Alpha AI...")
        print("="*60)
        print(f"\nTotal conversations: {conversation_count}")
        print("Goodbye! 👋\n")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        print("Alpha AI will now exit.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()