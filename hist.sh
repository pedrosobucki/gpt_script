#!/bin/bash

get_flags() {
    while getopts ":t:T:m:h" opt; do
        case $opt in
            h) help_info;;
            t) MAX_TOKENS=$OPTARG;;
            T) TEMPERATURE=$OPTARG;;
            m) MODEL=$OPTARG;;
            ?) echo "Invalid option \"-$OPTARG\""; exit 1;;
        esac
    done
}

get_json_history() {
    if [ ! -f $HIST_DIR/$1.json ]; then
        echo "Chat \"$1\" not found."
        exit 1
    fi

    cat $HIST_DIR/$1.json
}

list_history() {
    echo "Available chat history:"
    ls $HIST_DIR -1 | sed 's/\.json$//'  
}

show_history() {
    echo $(get_json_history $1) | jq
}

rm_history() {
    if [ ! -f $HIST_DIR/$1.json ]; then
        echo "Chat \"$1\" not found."
        exit 1
    fi

    rm $HIST_DIR/$1.json
}

case $2 in
    ls) list_history ${3:-chat1};;
    rm) rm_history ${3:-chat1};;
    *) list_history;;
esac
