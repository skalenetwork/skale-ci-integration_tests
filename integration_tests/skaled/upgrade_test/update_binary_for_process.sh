#!/bin/bash

# input:
# $1 - PID

echo "Updating binary for PID $1"

ARGS=$( cat /proc/$1/cmdline | xargs -0 )
IN=$( readlink /proc/$1/fd/0 )
OUT=$( readlink /proc/$1/fd/1 )
ERR=$( readlink /proc/$1/fd/2 )
CWD=$( readlink /proc/$1/cwd )

while IFS= read -r -d '' line; do
    locVar="${line/=/=\"}\""
    if [[ ${locVar:0:1} != "_" && ${locVar} != A__z* ]]; then
        eval "$locVar"
        eval "export ${locVar%%=*}"
    fi
done < "/proc/$1/environ"

echo "Killing $1 and waiting 1 min"
kill -15 $1
#tail --pid=$1 -f /dev/null
sleep 60

echo "Running:"
CMD="$ARGS 1>>$OUT 2>>$ERR"
echo "$CMD&"

cd $CWD
$ARGS 1>>$OUT 2>>$ERR&
