#!/bin/bash

SCRIPT_PATH=$PWD

if [ -f config ]; then
	echo "Configuration already setup!"
	exit 0
fi

read -p "Please provide an OpenAI API KEY: " key

if [ -z $key ]; then
	echo "- You MUST set an API KEY."
	echo "Generate it at: https://platform.openai.com/api-keys"
	exit 1
fi

read -p "Language Model [gpt-3.5-turbo]: " model
model=${model:-gpt-3.5-turbo}

read -p "Max generated tokens [150]: " max_tokens
max_tokens=${max_tokens:-150}

read -p "Temperature [0.2]: " temperature
temperature=${temperature:-0.2}

read -p "Max chat memory (will remember this many retrospective prompts) [5]: " max_chat_memory
max_chat_memory=${max_chat_memory:-5}

echo -e "KEY=$key\nMODEL=$model\nMAX_TOKENS=$max_tokens\nTEMPERATURE=$temperature\nMAX_CHAT_MEMORY=$max_chat_memory" >> config

case $SHELL in
	/bin/bash) FILE=$HOME/.bashrc;;
	/bin/zsh) FILE=$HOME/.zshrc;;
	/bin/fish) FILE=$HOME/.config/fish/config.fish;;
	*) echo "Could not locate shell to create shortcuts"; exit 1;;
esac

if [ ! $(cat $FILE | grep "alias ask*" | wc -l) -gt "0" ]; then
	echo -e "alias ask=\"$SCRIPT_PATH/gptask.sh \$@\"\nalias askcln=\"rm -f $SCRIPT_PATH/log\"" >> $FILE
fi

echo -e "- Configuration is complete!\nReload yout shell source to use 'ask' and 'askcln' commands."
