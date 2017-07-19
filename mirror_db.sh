#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

checkFlags() {
  if [ ! -d "$logsDir" ]; then
	  mkdir $logsDir
  fi

  if [ ! -z $DB_BACKUP_DIR ]; then
    SKIP_EXPORT=true
  fi

  if [ "$SKIP_IMPORT" = true ]; then
	  # Cannot drop entire database if skipping import process
	  dropTables=
	  dropTableSql=
  fi

  if [ "$dropTableSql" = true ]; then
	  # if drop tables using sql file, should not drop tables using wp cli method which is default
	  dropTables=false
  fi

  if [ "$parallelImport" = true ]; then
	  # Cannot drop entire database if running parallel-import
	  dropTables=
	  dropTableSql=
  fi
}

mirrorDbMain() {
  setGlobalVariables
  parseArgs $@
  checkFlags
  echo ""
  echo "Starting to execute mirror_db."
  echo "##############################"
  echo "Current time: $(date)"

  setFilePermissions

  if [[ $propertiesFile != "db.properties" && -e "$propertiesFile" ]]; then
	  echo "--properties-file option is set"
	  echo "Copying ${propertiesFile} to db.properties file in current dir"
	  cat $propertiesFile > db.properties
  fi

  if [ ! -z $src ]; then
    DB_FILE_NAME="${src}_$(date +"%Y-%m-%d").sql"
    echo "Executing db export script"
    uploadExportMain

    if [ "$parallelImport" = true ] || [ "$parallelImport" == '--parallel-import' ]; then
		  # Merge all tables to one mysql.sql
      echo "Executing merge script"
      #./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${mergeBatchLimit} ${parallelImport}
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