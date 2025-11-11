"""
Alpha AI LLM Module - Enhanced Version with Robust Error Handling

Improvements:
- Comprehensive error handling with retry logic
- Configuration validation
- Graceful degradation on failures
- Backup system for conversation history
- Rate limit and timeout handling
"""
import yaml
import json
import os
from groq import Groq
from groq import RateLimitError, APITimeoutError, APIConnectionError, GroqError
import time
import logging
from pathlib import Path

# Logging Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config():
    """
    Load configuration with comprehensive validation.

    Returns:
        dict: Configuration dictionary

    Raises:
        FileNotFoundError: If config file doesn't exist
        KeyError: If required keys are missing
        ValueError: If API key is invalid
    """
    config_path = 'character_config.yaml'

    try:
        if not os.path.exists(config_path):
            raise FileNotFoundError(
                f"❌ {config_path} not found! "
                f"Copy character_config.yaml.example and configure it."
            )

        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)

        # Validate required keys
        required_keys = ['GROQ_API_KEY', 'model', 'history_file', 'presets']
        for key in required_keys:
            if key not in config:
                raise KeyError(f"❌ Required key '{key}' missing in {config_path}")

        # Validate API key format
        api_key = config['GROQ_API_KEY']
        if api_key == 'gsk_YOURAPIKEY' or not api_key.startswith('gsk_'):
            raise ValueError(
                "❌ Please set a valid Groq API key in character_config.yaml"
            )

        logger.info(f"✓ Configuration loaded successfully")
        return config

    except yaml.YAMLError as e:
        logger.error(f"❌ YAML parsing error: {e}")
        raise
    except Exception as e:
        logger.error(f"❌ Configuration error: {e}")
        raise


# Load configuration
try:
    char_config = load_config()
    client = Groq(api_key=char_config['GROQ_API_KEY'])
    logger.info("✓ Groq client initialized")
except Exception as e:
    logger.error(f"Failed to initialize: {e}")
    raise

# Constants
HISTORY_FILE = char_config['history_file']
MODEL = char_config['model']
SYSTEM_PROMPT = [
    {
        "role": "system",
        "content": char_config['presets']['default']['system_prompt']
    }
]


def load_history():
    """
    Load conversation history with validation and error recovery.

    Returns:
        list: Conversation history or system prompt on error
    """
    try:
        if os.path.exists(HISTORY_FILE):
            with open(HISTORY_FILE, "r") as f:
                history = json.load(f)

            # Validate format
            if not isinstance(history, list):
                logger.warning(f"⚠️  Invalid history format, creating new")
                return SYSTEM_PROMPT

            logger.info(f"✓ Loaded history with {len(history)} messages")
            return history

        logger.info("No history file found, starting fresh")
        return SYSTEM_PROMPT

    except json.JSONDecodeError as e:
        logger.error(f"❌ Corrupted history file: {e}")

        # Backup corrupted file
        backup_path = f"{HISTORY_FILE}.corrupted.{int(time.time())}"
        try:
            os.rename(HISTORY_FILE, backup_path)
            logger.info(f"💾 Backed up corrupted file to {backup_path}")
        except Exception:
            pass

        logger.info("🔄 Starting with fresh history")
        return SYSTEM_PROMPT

    except Exception as e:
        logger.error(f"❌ Error loading history: {e}")
        return SYSTEM_PROMPT


def save_history(history):
    """
    Save conversation history with backup mechanism.

    Args:
        history: Conversation history to save
    """
    try:
        # Create backup of existing history
        if os.path.exists(HISTORY_FILE):
            backup_file = f"{HISTORY_FILE}.backup"
            try:
                with open(HISTORY_FILE, "r") as f:
                    backup_data = f.read()
                with open(backup_file, "w") as bf:
                    bf.write(backup_data)
            except Exception as e:
                logger.warning(f"⚠️  Could not create backup: {e}")

        # Save new history
        with open(HISTORY_FILE, "w") as f:
            json.dump(history, f, indent=2)

        logger.debug(f"✓ History saved ({len(history)} messages)")

    except Exception as e:
        logger.error(f"❌ Error saving history: {e}")


def get_ai_response(messages, max_retries=3):
    """
    Get AI response with comprehensive retry logic and error handling.

    Args:
        messages: Conversation history
        max_retries: Maximum retry attempts (default: 3)

    Returns:
        Response object or None on failure
    """
    for attempt in range(max_retries):
        try:
            logger.debug(f"Requesting AI response (attempt {attempt + 1}/{max_retries})")

            response = client.chat.completions.create(
                model=MODEL,
                messages=messages,
                temperature=1,
                top_p=1,
                max_tokens=2048,
                stream=False
            )

            logger.info("✓ AI response received")
            return response

        except RateLimitError as e:
            wait_time = (2 ** attempt) * 2  # Exponential backoff: 2s, 4s, 8s
            logger.warning(f"⚠️  Rate limit reached. Waiting {wait_time}s...")

            if attempt < max_retries - 1:
                time.sleep(wait_time)
            else:
                logger.error("❌ Rate limit: Maximum retries exceeded")
                return None

        except APITimeoutError as e:
            logger.warning(f"⚠️  API timeout (attempt {attempt + 1}/{max_retries})")

            if attempt < max_retries - 1:
                time.sleep(2)
            else:
                logger.error("❌ API timeout: Maximum retries exceeded")
                return None

        except APIConnectionError as e:
            logger.error(f"❌ Groq API connection error: {e}")

            # Retry on connection errors
            if attempt < max_retries - 1:
                logger.info("🔄 Retrying due to connection error...")
                time.sleep(2)
            else:
                return None

        except GroqError as e:
            logger.error(f"❌ Groq error: {e}")
            return None

        except Exception as e:
            logger.error(f"❌ Unexpected error: {e}", exc_info=True)
            return None

    return None


def llm_response(user_input):
    """
    Process user input and generate AI response with comprehensive error handling.

    Args:
        user_input: User's text input

    Returns:
        str: AI-generated response or fallback message
    """
    try:
        # Load conversation history
        messages = load_history()

        # Add user message
        messages.append({
            "role": "user",
            "content": user_input
        })

        # Get AI response
        ai_response = get_ai_response(messages)

        if ai_response is None:
            # Fallback message on failure
            fallback_msg = (
                "I'm experiencing connection issues right now. "
                "Please try again in a moment."
            )
            logger.warning("⚠️  Using fallback message")

            # Save history with fallback (maintain conversation flow)
            messages.append({
                "role": "assistant",
                "content": fallback_msg
            })
            save_history(messages)
            return fallback_msg

        # Normal processing - extract response from Groq format
        response_text = ai_response.choices[0].message.content

        # Add assistant message to history
        messages.append({
            "role": "assistant",
            "content": response_text
        })

        # Save updated history
        save_history(messages)

        return response_text

    except Exception as e:
        logger.error(f"❌ Critical error in llm_response: {e}", exc_info=True)
        return "An unexpected error occurred. Please try again."


# Health check function for monitoring
def health_check():
    """
    Check if LLM module is healthy and API is accessible.

    Returns:
        dict: Health status
    """
    health = {
        "status": "healthy",
        "config_loaded": False,
        "api_accessible": False,
        "history_readable": False
    }

    try:
        # Check config
        load_config()
        health["config_loaded"] = True

        # Check history file
        load_history()
        health["history_readable"] = True

        # Check API (quick test)
        test_response = client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "user", "content": "test"}],
            max_tokens=1,
            stream=False
        )
        health["api_accessible"] = True

    except Exception as e:
        health["status"] = "unhealthy"
        health["error"] = str(e)

    return health


if __name__ == "__main__":
    print('Testing enhanced LLM module...')

    # Health check
    print('\nHealth Check:')
    print(json.dumps(health_check(), indent=2))

    # Test response
    print('\nTest Response:')
    response = llm_response("Hello, this is a test.")
    print(f"Response: {response}")
