"""
Alpha AI Configuration Validator

Validates character_config.yaml to ensure all required fields are present
and properly formatted before starting the application.
"""
import yaml
import os
import sys
from pathlib import Path


def validate_config(config_path='character_config.yaml'):
    """
    Validate the character configuration file.

    Args:
        config_path: Path to the YAML configuration file

    Returns:
        tuple: (is_valid, config_dict, error_messages)
    """
    errors = []

    # Check if file exists
    if not os.path.exists(config_path):
        return False, None, [f"Configuration file not found: {config_path}"]

    # Load YAML
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        return False, None, [f"Invalid YAML format: {e}"]
    except Exception as e:
        return False, None, [f"Error reading config file: {e}"]

    # Validate required fields
    required_fields = {
        'OPENAI_API_KEY': str,
        'history_file': str,
        'model': str,
    }

    for field, expected_type in required_fields.items():
        if field not in config:
            errors.append(f"Missing required field: {field}")
        elif not isinstance(config[field], expected_type):
            errors.append(f"Field '{field}' must be of type {expected_type.__name__}")

    # Validate OpenAI API key format
    if 'OPENAI_API_KEY' in config:
        api_key = config['OPENAI_API_KEY']
        if api_key == 'sk-YOUR_API_KEY_HERE' or api_key == 'sk-YOURAPIKEY':
            errors.append("Please replace OPENAI_API_KEY with your actual OpenAI API key")
        elif not api_key.startswith('sk-'):
            errors.append("OPENAI_API_KEY should start with 'sk-'")

    # Validate presets
    if 'presets' not in config:
        errors.append("Missing 'presets' section in config")
    elif not isinstance(config['presets'], dict):
        errors.append("'presets' must be a dictionary")
    else:
        if 'default' not in config['presets']:
            errors.append("Missing 'default' preset in 'presets' section")
        elif 'system_prompt' not in config['presets']['default']:
            errors.append("Missing 'system_prompt' in default preset")

    # Validate sovits_ping_config
    if 'sovits_ping_config' not in config:
        errors.append("Missing 'sovits_ping_config' section")
    else:
        sovits_config = config['sovits_ping_config']
        required_sovits_fields = ['text_lang', 'prompt_lang', 'ref_audio_path', 'prompt_text']

        for field in required_sovits_fields:
            if field not in sovits_config:
                errors.append(f"Missing '{field}' in sovits_ping_config")

        # Check if reference audio file exists
        if 'ref_audio_path' in sovits_config:
            ref_audio_path = Path(sovits_config['ref_audio_path'])
            if not ref_audio_path.exists():
                errors.append(f"Reference audio file not found: {ref_audio_path}")

    # Validate optional fields
    if 'max_history_messages' in config:
        if not isinstance(config['max_history_messages'], int):
            errors.append("'max_history_messages' must be an integer")
        elif config['max_history_messages'] < 1:
            errors.append("'max_history_messages' must be at least 1")

    # Return validation result
    if errors:
        return False, config, errors
    return True, config, []


def print_validation_errors(errors):
    """Print validation errors in a user-friendly format."""
    print("\n" + "="*60)
    print("  CONFIGURATION VALIDATION FAILED")
    print("="*60)
    print("\nThe following errors were found in character_config.yaml:\n")

    for i, error in enumerate(errors, 1):
        print(f"  {i}. {error}")

    print("\n" + "="*60)
    print("Please fix these errors and try again.")
    print("="*60 + "\n")


if __name__ == "__main__":
    # Validate config when run directly
    is_valid, config, errors = validate_config()

    if is_valid:
        print("✓ Configuration is valid!")
        print(f"✓ Using model: {config['model']}")
        print(f"✓ History file: {config['history_file']}")
    else:
        print_validation_errors(errors)
        sys.exit(1)
