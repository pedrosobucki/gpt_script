#!/bin/bash

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

# read optional flags
while getopts ":t:T:m:h" opt; do
    case $opt in
        h) help_info;;
        t) MAX_TOKENS=$OPTARG;;
        T) TEMPERATURE=$OPTARG;;
        m) MODEL=$OPTARG;;
        ?) echo "Invalid option \"-$OPTARG\""; exit 1;;
    esac
done

echo -ne "  [ Generating... ]\033[0K\r"

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
echo -E cat $HIST_DIR/chat1.json | jq ".hist += [${MESSAGE}]"
exit

# saves prompt
cat $HIST_DIR/chat1.json | jq ".hist += [${PROMPT}]" > $HIST_DIR/chat1.json

ANSWER=$(echo -E $RESPONSE | jq '.choices | .[] | .message.content')

# saves context
cat $HIST_DIR/chat1.json | jq ".hist += [$(echo -E $RESPONSE | jq '.choices | .[] | .message')]" > $HIST_DIR/chat1.json

# erases old chat chat history
if [ $(cat $HIST_DIR/chat1.json | jq '.hist | length') -gt "$((MAX_CHAT_MEMORY * 2 + 1))" ]; then
	# awk 'NR>2' $HIST_DIR/chat1.json > $SCRIPT_PATH/tmp && mv $SCRIPT_PATH/tmp $HIST_DIR/chat1.json
    cat $HIST_DIR/chat1.json | jq '.hist | del(.[-2:])' > $HIST_DIR/chat1.json
fi

echo -e $ANSWER