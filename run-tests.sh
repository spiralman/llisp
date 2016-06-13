#!/bin/bash

TESTS=0
FAILURES=0

FAILURE_OUT=""

for TEST_FILE in `ls tests/test-*.llisp`; do
    TESTS=$(($TESTS + 1))
	  DIFF=$(lli llisp.bc $TEST_FILE | diff -u $TEST_FILE.out -)
    if [ $? == 0 ]
    then
        echo -n "."
    else
        FAILURES=$(($FAILURES + 1))
        FAILURE_OUT="${FAILURE_OUT}\nFailure in ${TEST_FILE}:\n\n${DIFF}\n"
        echo -n "F"
    fi
done


if [ $FAILURES == 0 ]
then
    echo -e "\nDone"
else
    echo -e "\n"
    printf "${FAILURE_OUT}"
    echo -e "\n${FAILURES} of ${TESTS} Tests Failed"

    exit 1
fi