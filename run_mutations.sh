#!/bin/bash

function runTests {
    MODULE=$1
    MODULE=`echo "$MODULE" | sed "s|\./||"`
    TEST=$2
    echo "Testing $MODULE with $TEST ..."
    if [ ! -f "$TEST" ]; then
        echo "$TEST doesn't exist. Aborting ..."
        exit 1
    fi

    LOG="logs/$MODULE.log"
    LOG=`echo $LOG | sed "s/\.py//"`
    JSON=`echo $LOG | sed "s/\.log/\.json/"`
    SURVIVAL=`echo $LOG | sed "s/\.log/\.sr/"`
    mkdir -p `dirname $LOG`

    # log mutations and existing test cases count
    cosmic-ray counts $MODULE >$LOG 2>&1
    PYTHONPATH=. python3 -m nose -s -I __init__.py -I baseclass.py $TEST >>$LOG 2>&1

    # execute mutation testing and log results
    export PYTHONPATH=. && cosmic-ray run --test-runner=nose --baseline=10 $JSON $MODULE -- \
                          -v --stop -I __init__.py -I baseclass.py $TEST

    # log the survival rate
    cosmic-ray survival-rate $JSON > $SURVIVAL
}

# run tools/ tests
for f in `find ./tools -type f -name "*.py" | sort`; do
    TEST_NAME=`echo $f | cut -f2-99 -d/`
    TEST_NAME="tests/$TEST_NAME"
    runTests $f $TEST_NAME
done

# run pykickstart/commands/ tests
for f in `find ./pykickstart/commands -type f -name "*.py" | sort`; do
    TEST_NAME=`echo $f | cut -f3-99 -d/`
    TEST_NAME="tests/$TEST_NAME"
    runTests $f $TEST_NAME
done

# run pykickstart/handlers/ tests
for f in `find ./pykickstart/handlers -type f -name "*.py" | sort`; do
    TEST_NAME="tests/handlers.py"
    runTests $f $TEST_NAME
done

# run pykickstart/*.py tests
for f in `find ./pykickstart -maxdepth 1 -type f -name "*.py" | sort`; do
    TEST_NAME=`echo $f | cut -f3-99 -d/`
    TEST_NAME="tests/$TEST_NAME"
    runTests $f $TEST_NAME
done
