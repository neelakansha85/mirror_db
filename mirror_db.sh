#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

checkFlags() {
  if [ ! -z $CUSTOM_DB_BACKUP_DIR ] && [ -z $SKIP_EXPORT ]; then
    readonly SKIP_EXPORT=true
  fi

  if [ "$SKIP_IMPORT" = true ]; then
	  # Cannot drop entire database if skipping import process
	  DROP_TABLES=false
	  DROP_TABLE_SQL=false
  fi
  
  if [ "$DROP_TABLE_SQL" = true ]; then
    # if drop tables using sql file, should not drop tables using wp cli method which is default
	  DROP_TABLES=false
  fi

  if [ "$PARALLEL_IMPORT" = true ]; then
	  # Cannot drop entire database if running parallel-import
	  DROP_TABLES=false
	  DROP_TABLE_SQL=false
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

#catch signal from export

  if [ ! -z $SRC ]; then
    echo "Executing db export script"
    uploadExportMain

    #catch signal here
    if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
		  # Merge all tables to one mysql.sql #echo "Executing merge script" #./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT} ${PARALLEL_IMPORT}#mergeMain
      #catch signal here, should bypass the export process
      trap 'echo "got SIGUSR1"; getDb; exit 0' SIGUSR1 &
	  fi
	fi

  if [ ! -z $DEST ]; then
		echo "Executing upload_import script"
		uploadImportMain
  fi
  exit
}

mirrorDbMain $@