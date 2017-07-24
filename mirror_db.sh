#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

checkFlags() {
  if [ ! -z $DB_BACKUP_DIR ]; then
    SKIP_EXPORT=true
  fi

  if [ "$NETWORK_FLAG" = true ]; then
    # This value has to be passed to export.sh on Src
    NETWORK_FLAG='--network-flag'
  fi

  if [ "$SKIP_IMPORT" = true ]; then
    # This value has to be passed over to import.sh on Dest
    SKIP_IMPORT='--skip-import'
	  # Cannot drop entire database if skipping import process
	  DROP_TABLES=
	  DROP_TABLE_SQL=
  fi
  
  if [ "$SKIP_REPLACE" = true ]; then
    # This value has to be passed over to import.sh on Dest
    SKIP_REPLACE='--skip-replace'
  fi  

  if [ "$SKIP_NETWORK_IMPORT" = true ]; then
    # This value has to be passed over to import.sh on Dest (PI)
    SKIP_NETWORK_IMPORT='--skip-network-import'
  fi

  if [ "$DROP_TABLE_SQL" = true ]; then
    #this value has to be passed over to import.sh on Dest
    DROP_TABLE_SQL=--drop-tables-sql
	  # if drop tables using sql file, should not drop tables using wp cli method which is default
	  DROP_TABLES=false
  fi

  if [ "$PARALLEL_IMPORT" = true ]; then
	  # Cannot drop entire database if running parallel-import
	  DROP_TABLES=
	  DROP_TABLE_SQL=
  fi
}

mirrorDbMain() {
  setGlobalVariables
  # Update options based on user's arguments
  parseArgs $@
  checkFlags
  
  echo ""
  echo "Starting to execute mirror_db."
  echo "##############################"
  echo "Current time: $(date)"
  prepareForDist
  # Create LOGS_DIR if doesn't exist
  mkdir -p $LOGS_DIR

  if [[ $PROPERTIES_FILE != "db.properties" && -e "$PROPERTIES_FILE" ]]; then
	  echo "--properties-file option is set"
	  echo "Copying ${PROPERTIES_FILE} to db.properties file in current dir"
	  cat $PROPERTIES_FILE > db.properties
  fi

  if [ ! -z $SRC ]; then
    echo "Executing db export script"
    uploadExportMain

    if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
		  # Merge all tables to one mysql.sql
      echo "Executing merge script"
      #./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT} ${PARALLEL_IMPORT}
      mergeMain
	  fi
	fi

  if [ ! -z $DEST ]; then
		echo "Executing upload_import script"
		uploadImportMain
  fi
  exit
}

mirrorDbMain $@