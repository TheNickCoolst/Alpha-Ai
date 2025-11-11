"""
Alpha AI LLM Module - ENHANCED

Handles conversation with Groq's LLM models, including:
- Conversation history management with memory limits
- System prompt configuration
- Response generation with timeout handling
- Robust error handling and retry logic
"""
import yaml
import json
import os
import time
from groq import Groq
from groq import APITimeoutError, APIConnectionError, RateLimitError

with open('character_config.yaml', 'r', encoding='utf-8') as f:
    char_config = yaml.safe_load(f)

client = Groq(
    api_key=char_config['GROQ_API_KEY'],
    timeout=30.0,  # 30 second timeout
    max_retries=2
)

# Constants
HISTORY_FILE = char_config.get('history_file', 'chat_history.json')
MODEL = char_config.get('model', 'llama-3.3-70b-versatile')
MAX_HISTORY_MESSAGES = char_config.get('max_history_messages', 50)  # Limit history to prevent memory issues

SYSTEM_PROMPT = [
    {
        "role": "system",
        "content": char_config['presets']['default']['system_prompt']
    }
]


def load_history():
    """
    Load conversation history from file.

    Returns:
        List of message dictionaries, or system prompt if no history exists
    """
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE, "r", encoding='utf-8') as f:
                history = json.load(f)
                # Ensure system prompt is always first
                if len(history) > 0 and history[0].get('role') != 'system':
                    history = SYSTEM_PROMPT + history
                return history
        except json.JSONDecodeError as e:
            print(f"⚠️  Error loading history file: {e}")
            print("⚠️  Starting with fresh history")
            return SYSTEM_PROMPT.copy()
        except Exception as e:
            print(f"⚠️  Unexpected error loading history: {e}")
            return SYSTEM_PROMPT.copy()
    return SYSTEM_PROMPT.copy()


def save_history(history):
    """
    Save conversation history to file with memory management.

    Args:
        history: List of message dictionaries to save
    """
    try:
        # Trim history if it exceeds max length
        # Keep system prompt + last N messages
        if len(history) > MAX_HISTORY_MESSAGES + 1:
            # Always keep system prompt (index 0) + most recent messages
            trimmed_history = [history[0]] + history[-(MAX_HISTORY_MESSAGES):]
            print(f"✓ Trimmed chat history to {MAX_HISTORY_MESSAGES} messages")
            history = trimmed_history

        with open(HISTORY_FILE, "w", encoding='utf-8') as f:
            json.dump(history, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"⚠️  Error saving history: {e}")


def get_ai_response(messages, retry_count=0, max_retries=3):
    """
    Get AI response from Groq API with timeout handling and retries.

    Args:
        messages: List of message dictionaries with conversation history
        retry_count: Current retry attempt
        max_retries: Maximum number of retries

    Returns:
        Groq API response object or None on failure
    """
    try:
        # Call Groq with system prompt + history
        response = client.chat.completions.create(
            model=MODEL,
            messages=messages,
            temperature=1,
            top_p=1,
            max_tokens=2048,
            stream=False
        )
        return response

    except APITimeoutError as e:
        print(f"⚠️  Groq API timeout (attempt {retry_count + 1}/{max_retries})")
        if retry_count < max_retries:
            wait_time = 2 ** retry_count  # Exponential backoff: 1s, 2s, 4s
            print(f"⏳ Retrying in {wait_time} seconds...")
            time.sleep(wait_time)
            return get_ai_response(messages, retry_count + 1, max_retries)
        else:
            print("❌ Max retries reached. API request failed.")
            return None

    except APIConnectionError as e:
        print(f"⚠️  Connection error: Cannot reach Groq API")
        print(f"⚠️  Check your internet connection")
        if retry_count < max_retries:
            wait_time = 2 ** retry_count
            print(f"⏳ Retrying in {wait_time} seconds...")
            time.sleep(wait_time)
            return get_ai_response(messages, retry_count + 1, max_retries)
        return None

    except RateLimitError as e:
        print(f"⚠️  Rate limit exceeded. Please wait and try again.")
        if retry_count < max_retries:
            wait_time = 10 * (retry_count + 1)  # Longer wait for rate limits
            print(f"⏳ Waiting {wait_time} seconds...")
            time.sleep(wait_time)
            return get_ai_response(messages, retry_count + 1, max_retries)
        return None

    except Exception as e:
        print(f"❌ Unexpected error calling Groq API: {e}")
        return None


def llm_response(user_input):
    """
    Process user input and generate AI response with conversation history.
    Enhanced with timeout handling and error recovery.

    Args:
        user_input: User's text input

    Returns:
        AI-generated response text or fallback message
    """
    if not user_input or user_input.strip() == "":
        return "I didn't catch that. Could you please repeat?"

    messages = load_history()

    # Append user message to memory
    messages.append({
        "role": "user",
        "content": user_input
    })

    # Get AI response with retry logic
    ai_response = get_ai_response(messages)

    if ai_response is None:
        # Fallback response if API fails
        fallback_text = "I'm sorry, I'm having trouble connecting right now. Could you try again in a moment?"
        # Don't save failed interactions to history
        return fallback_text

    # Extract response text from Groq API response
    response_text = ai_response.choices[0].message.content

    # Append assistant message to conversation history
    messages.append({
        "role": "assistant",
        "content": response_text
    })

    save_history(messages)
    return response_text


if __name__ == "__main__":
    print('running main')