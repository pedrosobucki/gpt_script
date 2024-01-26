#!/bin/bash

get_json_history() {
    if [ ! -f log ]; then
        echo "No history."
        exit 0
    fi

    HISTORY='{"hist":['$(cat $SCRIPT_PATH/log)']}'

    echo $HISTORY
}

display_history() {
    echo $(get_json_history) | jq
}

rm_history() {
    rm $HIST_DIR/$1
}

case $2 in
    ls) display_history ${@: -1};;
    *) source ./ask.sh;;
esac
