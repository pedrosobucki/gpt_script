#!/bin/bash


SCRIPT_PATH=$(dirname $0)
PREV_CONTEXT=$(cat $SCRIPT_PATH/log 2> /dev/null)
PROMPT="{
	\"role\": \"user\",
	\"content\": \"$1\"
}"

# imports config variables
CONFIG=$SCRIPT_PATH/config

if [ ! -f $CONFIG ]; then
	CONFIG=$SCRIPT_PATH/config.example
fi

export $(grep -v '^#' $CONFIG | xargs)

if [ -z $KEY ]; then
	echo "You must provide an API KEY."
	exit 1
fi

# read optional flags
while getopts ":t:T:m:" opt; do
        case $opt in
                t) MAX_TOKENS=$OPTARG;;
                T) TEMPERATURE=$OPTARG;;
                m) MODEL=$OPTARG;;
                ?) echo "Invalid option \"-$OPTARG\""; exit 1;;
        esac
done

echo -ne "  [ Generating... ]\033[0K\r"

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer $KEY" -d "
        {
	\"model\": \"$MODEL\",
	\"messages\": [
		{
			\"role\": \"system\",
			\"content\": \"You are a helpful linux shell application which will have it's output response printed in the terminal, so use only characters which are terminal friendly whe writing your answer. You also should write concise messages, as the user will prompt you again if more detailed information is needed.\"
		},
		$PREV_CONTEXT
		$PROMPT
	],
	\"max_tokens\": $MAX_TOKENS, 
	\"temperature\": $TEMPERATURE
}")

# cleans "searching" line
echo -ne "                    \033[0K\r"

# checks if error occured in fetch
ERROR=$(echo -E $RESPONSE | jq .error.message)
if [ -n "$ERROR" ]; then
	echo "ERROR: $ERROR"
	exit 1
fi

# saves prompt
echo -E $PROMPT, >> $SCRIPT_PATH/log

ANSWER=$(echo -E $RESPONSE | jq '.choices | .[] | .message.content')

# saves context
echo -E $(echo -E $RESPONSE | jq '.choices | .[] | .message'), >> $SCRIPT_PATH/log
 $ERROR"
 exit 1
# erases old chat log
if [ $(cat $SCRIPT_PATH/log 2> /dev/null | wc -l) -gt "$((MAX_CHAT_MEMORY * 2 + 1))" ]; then
	awk 'NR>2' $SCRIPT_PATH/log > $SCRIPT_PATH/tmp && mv $SCRIPT_PATH/tmp $SCRIPT_PATH/log
fi


echo -e $ANSWER
