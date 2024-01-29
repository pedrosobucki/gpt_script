#!/bin/bash

SCRIPT_PATH=$(dirname $0)
PREV_CONTEXT=$(cat $SCRIPT_PATH/log 2> /dev/null)
OUTPUT=/dev/stdout

# retrieves stdin if exists
STDIN=""
if [ ! -t 0 ]; then
	while IFS= read -r line; do
		STDIN="$STDIN\n$(echo -E $line)"
	done
fi

# imports config variables
CONFIG=$SCRIPT_PATH/config.example
export $(grep -v '^#' $CONFIG | xargs)

if [ -f $SCRIPT_PATH/config ]; then
	CONFIG=$SCRIPT_PATH/config
fi

export $(grep -v '^#' $CONFIG | xargs)

if [ -z $KEY ]; then
	echo "You must provide an API KEY."
	exit 1
fi

help_info() {
	echo -e "Flags:\n\t-h: Display help info\n\t-t: Changes max tokens returned by request (_MAX\_TOKENS_)\n\t-m: Changes model used in request (_MODEL_)\n\t-T: Changes temperature for promp processing (_TEMPERATURE_)\n\t-r: Returns RAW code, without any extra information or formatting"
	exit 0
}

RAW=false

# read optional flags
while getopts ":t:T:m:hr" opt; do
        case $opt in
		h) help_info;;
                t) MAX_TOKENS=$OPTARG;;
                T) TEMPERATURE=$OPTARG;;
                m) MODEL=$OPTARG;;
                r) RAW=true;;
                ?) echo "Invalid option \"-$OPTARG\""; exit 1;;
        esac
done

RAW_MOD=
if [ $RAW = "true" ]; then
    RAW_MOD=". This specific response should only be code, without explanations, markdown formating or anything other than the code itself."
    OUTPUT=/dev/null
fi

# treats prompt special chars for json format
PROMPT='{
	"role": "user",
	"content": "'$(echo -E ${@: -1} $STDIN | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')$RAW_MOD'"
}'

echo -ne "  [ Generating... ]\033[0K\r" > $OUTPUT

CURRENT_DIR=
if [ $KNOW_CURRENT_DIR = "true" ]; then
	CURRENT_DIR="You are currently in the $PWD directory."
fi

BODY='{
	"model": "'$MODEL'",
	"messages": [
		{
			"role": "system",
			"content": "You are a helpful linux shell application which will have its output response printed in the terminal, so use only characters which are terminal friendly whe writing your answer. You also should write concise messages, as the user will prompt you again if more detailed information is needed. The current user is '$USER'.'$CURRENT_DIR'"
		},
		'$PREV_CONTEXT'
		'${PROMPT}'
	],
	"max_tokens": '$MAX_TOKENS', 
	"temperature": '$TEMPERATURE'
}'

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer $KEY" -d "$BODY")

# cleans "searching" line
echo -ne "                    \033[0K\r" > $OUTPUT

# checks if error occured in fetch
ERROR=$(echo -E $RESPONSE | jq .error.message)
if [ "$ERROR" != "null" ]; then
	echo "ERROR: $ERROR"
	exit 1
fi

# saves prompt
echo -E $PROMPT, >> $SCRIPT_PATH/log

ANSWER=$(echo -E $RESPONSE | jq '.choices | .[] | .message.content')

# saves context
echo -E $(echo -E $RESPONSE | jq '.choices | .[] | .message'), >> $SCRIPT_PATH/log

# erases old chat log
if [ $(cat $SCRIPT_PATH/log 2> /dev/null | wc -l) -gt "$((MAX_CHAT_MEMORY * 2 + 1))" ]; then
	awk 'NR>2' $SCRIPT_PATH/log > $SCRIPT_PATH/tmp && mv $SCRIPT_PATH/tmp $SCRIPT_PATH/log
fi

# parsed json response to regular string
PARSED=$(echo -E $ANSWER | sed 's/\\\"/\"/g')
PARSED=${PARSED:1:-1}

# removes markdown code block if exists and wants raw output
if [ $RAW = "true" ]; then
    echo -e $PARSED | sed '/```/d'
    exit 0
fi

echo -e $PARSED