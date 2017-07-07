#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

checkFlagValue() {
  if [ ! -d "$LOGS_DIR" ]; then
	  mkdir $LOGS_DIR
  fi

  if [ ! -z $DB_BACKUP_DIR ]; then
    SKIP_EXPORT=true
  fi

  if [ "$SKIP_EXPORT" = true ]; then
	  DB_BACKUP_DIR=${DB_BACKUP_DIR}
  fi

  if [ "$SKIP_IMPORT" = true ]; then
	  # Cannot drop entire database if skipping import process
	  DROP_TABLES=
	  DROP_TABLES_SQL=
  fi

  if [ "$PARALLEL_IMPORT" = true ]; then
	  # Cannot drop entire database if running parallel-import
	  DROP_TABLES=
	  DROP_TABLES_SQL=
  fi
}

mirrorDbMain() {
  setGlobalVariables
  parseArgs $@
  checkFlagValue
  echo ""
  echo "Starting to execute mirror_db."
  echo "##############################"
  echo "Current time: $(date)"

  setFilePermissions

  if [[ $PROPERTIES_FILE != "db.properties" && -e "$PROPERTIES_FILE" ]]; then
	  echo "--properties-file option is set"
	  echo "Copying ${PROPERTIES_FILE} to db.properties file in current dir"
	  cat $PROPERTIES_FILE > db.properties
  fi

  if [ ! -z $SRC ]; then
    DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d").sql"
    echo "Executing db export script"
    uploadExportMain

    if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
		  # Merge all tables to one mysql.sql
      echo "Executing merge script"
      #./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT} ${PARALLEL_IMPORT}
      mergeMain
	  fi

	  readProperties $SRC
	  SRC_URL=$URL
	  SRC_SHIB_URL=$SHIB_URL
	  SRC_G_ANALYTICS=$G_ANALYTICS
	fi

  # TODO: Need to fix below condition $DB_BACKUP_DIR is now directly by putDb()
  if [ -z $DB_BACKUP_DIR ]; then
    echo "No alternate for database path found"
    DB_BACKUP_DIR="''"
  fi

  if [ ! -z $DEST ]; then
		echo "Executing upload_import script"
		uploadImportMain
  fi
  exit
}
mirrorDbMain $@