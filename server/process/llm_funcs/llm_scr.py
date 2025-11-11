"""
Alpha AI LLM Module

Handles conversation with OpenAI's GPT models, including:
- Conversation history management
- System prompt configuration
- Response generation
"""
import yaml
import json
import os
from openai import OpenAI

with open('character_config.yaml', 'r') as f:
    char_config = yaml.safe_load(f)

client = OpenAI(api_key=char_config['OPENAI_API_KEY'])

# Constants
HISTORY_FILE = char_config['history_file']
MODEL = char_config['model']
SYSTEM_PROMPT =  [
        {
            "role": "system",
            "content": [
                {
                    "type": "input_text",
                    "text": char_config['presets']['default']['system_prompt']  
                }
            ]
        }
    ]

def load_history():
    """
    Load conversation history from file.

    Returns:
        List of message dictionaries, or system prompt if no history exists
    """
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, "r") as f:
            return json.load(f)
    return SYSTEM_PROMPT

def save_history(history):
    """
    Save conversation history to file.

    Args:
        history: List of message dictionaries to save
    """
    with open(HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2)



def get_ai_response(messages):
    """
    Get AI response from OpenAI API without tool calling.

    Args:
        messages: List of message dictionaries with conversation history

    Returns:
        OpenAI API response object
    """
    # Call OpenAI with system prompt + history
    response = client.responses.create(
        model=MODEL,
        input=messages,
        temperature=1,
        top_p=1,
        max_output_tokens=2048,
        stream=False,
        text={
            "format": {
                "type": "text"
            }
        },
    )

    return response


def llm_response(user_input):
    """
    Process user input and generate AI response with conversation history.

    Args:
        user_input: User's text input

    Returns:
        AI-generated response text
    """
    messages = load_history()

    # Append user message to memory
    messages.append({
        "role": "user",
        "content": [
            {"type": "input_text", "text": user_input}
        ]
    })

    ai_response = get_ai_response(messages)

    # Append assistant message to conversation history
    messages.append({
        "role": "assistant",
        "content": [
            {"type": "output_text", "text": ai_response.output_text}
        ]
    })

    save_history(messages)
    return ai_response.output_text


if __name__ == "__main__":
    print('running main')