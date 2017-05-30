#!/bin/bash

parseArgs() {

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
      -blogid )
        BLOG_ID=$2
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
      --network-flag)
        NETWORK_FLAG=true
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

}