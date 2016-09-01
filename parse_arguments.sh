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

        elif [ "${myarray[i]}" == "-ebl" ]; then
            i=`expr ${i}+1`
            BATCH_LIMIT=${myarray[i]}

        elif [ "${myarray[i]}" == "-pl" ]; then
            i=`expr ${i}+1`
            POOL_LIMIT=${myarray[i]}

        elif [ "${myarray[i]}" == "-mbl" ]; then
            i=`expr ${i}+1`
            MERGE_BATCH_LIMIT=${myarray[i]}

        elif [ "${myarray[i]}" == "-ewt" ]; then
            i=`expr ${i}+1`
            WAIT_TIME=${myarray[i]}

        elif [ "${myarray[i]}" == "-iwt" ]; then
            i=`expr ${i}+1`
            IMPORT_WAIT_TIME=${myarray[i]}

        elif [ "${myarray[i]}" == "-lf" ]; then
            i=`expr ${i}+1`
            LIST_FILE_NAME=${myarray[i]}

        elif [ "${myarray[i]}" == "-dbf" ]; then
            i=`expr ${i}+1`
            DB_FILE_NAME=${myarray[i]}

        elif [ "${myarray[i]}" == "--site-url" ]; then
            i=`expr ${i}+1`
            SRC_URL=${myarray[i]}

        elif [ "${myarray[i]}" == "--shib-url" ]; then
            i=`expr ${i}+1`
            SRC_SHIB_URL=${myarray[i]}

        elif [ "${myarray[i]}" == "--g-analytics" ]; then
            i=`expr ${i}+1`
            SRC_G_ANALYTICS=${myarray[i]}

        elif [ "${myarray[i]}" == "--force" ]; then
            FORCE_IMPORT='--force'

        elif [ "${myarray[i]}" == "--drop-tables" ]; then
            DROP_TABLES=true

        elif [ "${myarray[i]}" == "--drop-tables-sql" ]; then
            DROP_TABLES_SQL=true

        elif [ "${myarray[i]}" == "--skip-export" ]; then
            SKIP_EXPORT=true

        elif [ "${myarray[i]}" == "--skip-import" ]; then
            SKIP_IMPORT=true
        
        elif [ "${myarray[i]}" == "--parallel-import" ]; then
            PARALLEL_IMPORT=true

        elif [ "${myarray[i]}" == "--is-last-import" ]; then
            IS_LAST_IMPORT=true

        else
            echo "Please select correct option"
            exit 1
        fi
    done

    export SRC
    export DEST
    export BATCH_LIMIT
    export POOL_LIMIT
    export MERGE_BATCH_LIMIT
    export WAIT_TIME
    export IMPORT_WAIT_TIME
    export LIST_FILE_NAME
    export DB_FILE_NAME
    export SRC_URL
    export SRC_SHIB_URL
    export SRC_G_ANALYTICS
    export FORCE_IMPORT
    export DROP_TABLES
    export DROP_TABLES_SQL
    export SKIP_EXPORT
    export SKIP_IMPORT
    export PARALLEL_IMPORT
    export IS_LAST_IMPORT
    
    return
else
    echo "Please enter compulsory arguments"
    exit 1
fi