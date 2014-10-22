#!/bin/sh
set -o noglob
# ------------------------------------------------------------------------------
AURL="https://auth.selcdn.ru"
USER="$1"
UPWD="$2"
CONTAINER="$3"

if [[ -z "$AURL" || -z "$USER" || -z "$UPWD"  || -z "$CONTAINER" ]]; then
    echo "[ERROR] USAGE: ./test.sh USER PASSWORD CONTAINER"
    exit 1
fi

DEST="$CONTAINER/supload-test-`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 3`"
FILE1="./supload.sh"
FILE2="./README"
DIR1="./"

SUPLOAD="./supload.sh"
# ------------------------------------------------------------------------------

last_cmd=
last_retcode=
last_output=

_test() {
    echo "[TEST] $1"
    last_cmd="$2"
    last_output=`$last_cmd`
    last_retcode=$?

    return $last_retcode
}

_fail() {
    echo "[FAILED] $last_cmd = $last_retcode"
    echo "$1"
    echo "$last_output"
    echo ""
}

test_ok() {
    _test "$@"

    if [ $last_retcode -ne 0 ]; then
        _fail
        return 1
    fi
}

with_match() {
    echo $last_output | grep "$1" > /dev/null

    if [ $? -ne 0 ]; then
        _fail "^^^^^^^^ '$1' no found"
        return 1
    fi
}
with_not() {
    echo $last_output | grep -v "$1" > /dev/null

    if [ $? -ne 0 ]; then
        _fail "^^^^^^^^ '$1' must not be"
        return 1
    fi
}

# ------------------------------- Tests ----------------------------------------


test_ok "single upload" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD $DEST $FILE1" \
    && with_match "${FILE1:2}" \
    && with_match "Uploaded OK" \
&& echo "[ OK ]"

test_ok "single upload: again" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD $DEST $FILE1" \
    && with_match "${FILE1:2}" \
    && with_match "File already uploaded" \
&& echo "[ OK ]"

test_ok "single upload: force and speed limit (-M -s)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -M -s 1M $DEST $FILE1" \
    && with_match "${FILE1:2}" \
    && with_match "Uploaded OK" \
&& echo "[ OK ]"

test_ok "single upload: auto delete (-d)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -d 7d $DEST $FILE2" \
    && with_match "${FILE2:2}" \
    && with_match "Uploaded OK" \
&& echo "[ OK ]"

test_ok "single upload: auto delete again (-d)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -d 7d $DEST $FILE2" \
    && with_match "${FILE2:2}" \
    && with_match "File already uploaded" \
&& echo "[ OK ]"

test_ok "recursive upload (-r)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r $DEST $DIR1" \
    && with_match ".git/" \
    && with_match "${FILE1:2}" \
    && with_match "${FILE2:2}" \
    && with_match "All files uploaded" \
&& echo "[ OK ]"

test_ok "recursive upload: again (-r)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r $DEST $DIR1" \
    && with_match ".git/" \
    && with_match "${FILE1:2}" \
    && with_match "${FILE2:2}" \
    && with_match "All files uploaded" \
    && with_match "File already uploaded" \
    && with_not "Uploaded OK" \
&& echo "[ OK ]"

test_ok "recursive upload: force and speed limit (-r -M -s)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r -M -s 1M $DEST $DIR1" \
    && with_match ".git/" \
    && with_match "${FILE1:2}" \
    && with_match "${FILE2:2}" \
    && with_match "All files uploaded" \
    && with_match "Uploaded OK" \
    && with_not "File already uploaded" \
&& echo "[ OK ]"

test_ok "recursive upload: exclude one (-r -e)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r -e .git/* $DEST/r1/ $DIR1" \
    && with_not ".git/" \
    && with_match "${FILE1:2}" \
    && with_match "${FILE2:2}" \
    && with_match "All files uploaded" \
&& echo "[ OK ]"

test_ok "recursive upload: exclude many (-r -e -e -e)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r -e .git/* -e ${FILE1:2} -e ${FILE2:2} $DEST/r2/ $DIR1" \
    && with_not ".git/" \
    && with_not "${FILE1:2}" \
    && with_not "${FILE2:2}" \
    && with_match "All files uploaded" \
    && with_match "Uploaded OK" \
&& echo "[ OK ]"

echo "file-for-test-mtime" > ./file-for-test-mtime
test_ok "recursive upload: mtime filter (-r -m)" \
    "$SUPLOAD -a $AURL -u $USER -k $UPWD -r -m -1 $DEST $DIR1" \
    && with_not "LICENSE" \
    && with_match "file-for-test-mtime" \
    && with_match "All files uploaded" \
&& echo "[ OK ]"
rm ./file-for-test-mtime
