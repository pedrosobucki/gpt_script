# Description
GPT API applied to shell via bash script

# Setup
Run the **setup script** in order to configurate script:

```bash
$ ./setup.sh
```

Reload your shell configuration file:

EX (zsh):
```bash
$ source ~/.zshrc
```

# Usage
To run the script, use the **ask** command followed by your promp

### Command:
```bash 
$ ask "who are you?"
```

### Response
```bash
"I am a helpful Linux shell assistant here to assist you with any questions or problems you may have. I can provide information, guidance, and execute commands in the Linux shell environment. How can I assist you today?"
```

## Flags
There are optional flags for overwriting some configuration fields

- **-t**: Changes max tokens returned by request (_MAX\_TOKENS_)
- **-m**: Changes model used in request (_MODEL_)
- **-T**: Changes temperature for promp processing (_TEMPERATURE_)

### Example
```bash
$ ask -t 300 -m gpt-4 -T 0.7 "tell me about linux"
```

# References
- [OpenAI API Docs](https://platform.openai.com/docs/api-reference/introduction)
