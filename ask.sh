#!/bin/bash

OUTPUT=/dev/stdout

if [ -z $KEY ]; then
	echo "You must provide an API KEY."
	exit 1
fi

# treats prompt special chars for json format
PROMPT='{
	"role": "user",
	"content": "'$(echo -E ${@: -1} $STDIN | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')'"
}'

help_info() {
	echo -e "Flags:\n\t-h: Display help info\n\t-t: Changes max tokens returned by request (_MAX\_TOKENS_)\n\t-m: Changes model used in request (_MODEL_)\n\t-T: Changes temperature for promp processing (_TEMPERATURE_)"
	exit 0
}

save_to_hist() {
    LOG=$(cat $HIST_DIR/chat1.json | jq ".hist += [$1]")
    echo -E $LOG > $HIST_DIR/chat1.json
}

RAW=false

# read optional flags
while getopts ":t:T:m:rh" opt; do
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

CURRENT_DIR=
if [ $KNOW_CURRENT_DIR = "true" ]; then
	CURRENT_DIR="You are currently in the $PWD directory."
fi

# treats prompt special chars for json format
PROMPT='{
	"role": "user",
	"content": "'$(echo -E ${@: -1} $STDIN | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')$RAW_MOD'"
}'

echo -ne "  [ Generating... ]\033[0K\r" > $OUTPUT

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
echo -ne "                    \033[0K\r"

# checks if error occured in fetch
ERROR=$(echo -E $RESPONSE | jq .error.message)
if [ "$ERROR" != "null" ]; then
	echo "ERROR: $ERROR"
	exit 1
fi

MESSAGE=$(echo -E $RESPONSE | jq '.choices | .[] | .message')

# saves prompt
LOG=$(cat $HIST_DIR/chat1.json | jq ".hist += [${PROMPT}]")
echo -E $LOG > $HIST_DIR/chat1.json

ANSWER=$(echo -E $MESSAGE | jq '.content')

# saves context
LOG=$(cat $HIST_DIR/chat1.json | jq ".hist += [$MESSAGE]")
echo -E $LOG > $HIST_DIR/chat1.json

# erases old chat chat history
if [ "$(cat $HIST_DIR/chat1.json | jq '.hist | length')" == "$((MAX_CHAT_MEMORY * 2 + 1))" ]; then
    LOG=$(cat $HIST_DIR/chat1.json | jq '.hist | del(.[-2:])')
    echo -E $LOG > $HIST_DIR/chat1.json
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