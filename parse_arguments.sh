#!/bin/bash

if [ ! $# -ge 2 ]; then
    echo "Please enter the source or destination to run"
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
      -s | --source)
        SRC=$2
        shift
        ;;
      -d | --destination)
        DEST=$2
        shift
        ;;
      --db-backup)
        DB_BACKUP=$2
        shift
        ;;
      -ebl )
        BATCH_LIMIT=$2
        shift
        ;;
      -pl )
        POOL_LIMIT=$2
        shift
        ;;
      -mbl )
        MERGE_BATCH_LIMIT=$2
        shift
        ;;
      -ewt )
        WAIT_TIME=$2
        shift
        ;;
      -iwt )
        IMPORT_WAIT_TIME=$2
        shift
        ;;
      -lf )
        LIST_FILE_NAME=$2
        shift
        ;;
      -dbf )
        DB_FILE_NAME=$2
        shift
        ;;
      -pf | --properties-file )
        PROPERTIES_FILE=$2
        shift
        ;;
      --site-url )
        SRC_URL=$2
        shift
        ;;
      --shib-url )
        SRC_SHIB_URL=$2
        shift
        ;;
      --g-analytics )
        SRC_G_ANALYTICS=$2
        ;;
      --force )
        FORCE_IMPORT=--force
        ;;
      --drop-tables)
        DROP_TABLES=true
        ;;
      --drop-tables-sql)
        DROP_TABLES_SQL=true
        ;;
      --skip-export)
        SKIP_EXPORT=true
        ;;
      --skip-import)
        SKIP_IMPORT=true
        ;;
      --skip-network-import)
        SKIP_NETWORK_IMPORT=true
        ;;
      --skip-replace)
        SKIP_REPLACE=true
        ;;
      --parallel-import)
        PARALLEL_IMPORT=true
        ;;
      --is-last-import)
        IS_LAST_IMPORT=true
        ;;
      -- ) 
        shift; 
        break 
        ;;
      * ) 
        break 
        ;;
    esac
    shift
done

export SRC
export DEST
export DB_BACKUP
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
export SKIP_NETWORK_IMPORT
export SKIP_REPLACE
export PARALLEL_IMPORT
export IS_LAST_IMPORT
export PROPERTIES_FILE