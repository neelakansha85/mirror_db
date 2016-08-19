#!/bin/bash
myarray=("$@")

if [ $# -ge 2 ]; then

    for (( i=0; i < $# ; i++ )); 
    do 
        if [ "${myarray[i]}" == "-s" ]; then
            i=`expr ${i}+1`
            SRC=${myarray[i]} 

        elif [ "${myarray[i]}" == "-d" ]; then
            i=`expr ${i}+1`
            DEST=${myarray[i]}

        elif [ "${myarray[i]}" == "-bl" ]; then
            i=`expr ${i}+1`
            BATCH_LIMIT=${myarray[i]}

        elif [ "${myarray[i]}" == "-wt" ]; then
            i=`expr ${i}+1`
            WAIT_TIME=${myarray[i]}

        elif [ "${myarray[i]}" == "-lf" ]; then
            i=`expr ${i}+1`
            LIST_FILE_NAME=${myarray[i]}

        elif [ "${myarray[i]}" == "-dbf" ]; then
            i=`expr ${i}+1`
            DB_FILE_NAME=${myarray[i]}

        elif [ "${myarray[i]}" == "-site-url" ]; then
            i=`expr ${i}+1`
            SRC_URL=${myarray[i]}

        elif [ "${myarray[i]}" == "-shib" ]; then
            i=`expr ${i}+1`
            SRC_SHIB_URL=${myarray[i]}

        elif [ "${myarray[i]}" == "-g-analytics" ]; then
            i=`expr ${i}+1`
            SRC_G_ANALYTICS=${myarray[i]}

        else
            echo "Please select correct option"
            exit 1
        fi
    done

    export SRC
    export DEST
    export BATCH_LIMIT
    export WAIT_TIME
    export LIST_FILE_NAME
    export DB_FILE_NAME
    export SRC_URL
    export SRC_SHIB_URL
    export SRC_G_ANALYTICS
    
    return
else
    echo "Please enter compulsory arguments"
    exit 1
fi