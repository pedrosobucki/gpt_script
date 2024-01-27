#!/bin/bash

SCRIPT_PATH=$(dirname $0)
HIST_DIR=$SCRIPT_PATH/hist

if [ ! -f $HIST_DIR/chat1.json ]; then
    echo '{"hist":[]}' > $HIST_DIR/chat1.json
fi

# retrieves previous prompts context 
PREV_CONTEXT=$(cat $HIST_DIR/chat1.json | jq '.hist')
PREV_CONTEXT=${PREV_CONTEXT:1:-1}

# imports config variables
export $(grep -v '^#' $SCRIPT_PATH/config.example | xargs)

if [ -f $SCRIPT_PATH/config ]; then
	export $(grep -v '^#' $SCRIPT_PATH/config | xargs)
fi

CURRENT_DIR=
if [ $KNOW_CURRENT_DIR = "true" ]; then
	CURRENT_DIR="You are currently in the $PWD directory."
fi

# retrieves stdin if exists
STDIN=
if [ ! -t 0 ]; then
	while IFS= read -r line; do
		STDIN="$STDIN\n$(echo -E $line)"
	done
fi

case $1 in
    hist) source $SCRIPT_PATH/hist.sh;;
    *) source $SCRIPT_PATH/ask.sh;;
esac