#!/bin/bash
set -e

source ./config.sh

[ -z "$1" ] && echo "need one argument to post to slack. Exit." && exit 1
content="{\"text\": \"$1\"}"

curl -X POST -H "Content-type: application/json" --data "${content}" ${SLACKWEBHOOK}
echo
