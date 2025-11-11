"""
Alpha AI Main Chat Loop

Orchestrates the complete voice conversation pipeline:
1. Record user voice (push-to-talk)
2. Transcribe speech to text (Faster-Whisper)
3. Generate AI response (OpenAI GPT)
4. Synthesize response to speech (GPT-SoVITS)
5. Play audio back to user

Requirements:
- GPT-SoVITS server running on port 9880
- Valid OpenAI API key in character_config.yaml
- Working microphone for input
"""
from faster_whisper import WhisperModel
from process.asr_func.asr_push_to_talk import record_and_transcribe
from process.llm_funcs.llm_scr import llm_response
from process.tts_func.sovits_ping import sovits_gen, play_audio
from pathlib import Path
import os
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
    with sf.SoundFile(path) as f:
        return len(f) / f.samplerate


print('\n========= Alpha AI Starting... =========\n')
print('Initializing Whisper model...')
whisper_model = WhisperModel("base.en", device="cpu", compute_type="float32")
print('✓ Ready for conversation!\n')

while True:
    # Step 1: Record user input
    conversation_recording = Path("audio") / "conversation.wav"
    conversation_recording.parent.mkdir(parents=True, exist_ok=True)

    print("🎤 Waiting for your input...")
    user_spoken_text = record_and_transcribe(whisper_model, conversation_recording)
    print(f"You said: {user_spoken_text}")

    # Step 2: Get LLM response
    print("🤔 Alpha is thinking...")
    llm_output = llm_response(user_spoken_text)
    print(f"Alpha: {llm_output}")

    # Step 3: Generate unique filename for TTS output
    uid = uuid.uuid4().hex
    filename = f"output_{uid}.wav"
    output_wav_path = Path("audio") / filename
    output_wav_path.parent.mkdir(parents=True, exist_ok=True)

    # Step 4: Generate and play audio response
    print("🔊 Generating speech...")
    gen_aud_path = sovits_gen(llm_output, output_wav_path)

    if gen_aud_path:
        print("▶️  Playing response...")
        play_audio(output_wav_path)
    else:
        print("⚠️  Could not generate audio. Check if GPT-SoVITS server is running.")

    # Step 5: Cleanup temporary audio files
    [fp.unlink() for fp in Path("audio").glob("*.wav") if fp.is_file()]
    print("\n" + "="*50 + "\n")