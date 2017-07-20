#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

checkFlags() {
  if [ ! -z $DB_BACKUP_DIR ]; then
    skipExport=true
  fi

  if [ "$skipImport" = true ]; then
    # This value has to be passed over to import.sh on Dest
    skipImport='--skip-import'
	  # Cannot drop entire database if skipping import process
	  dropTables=
	  dropTableSql=
  fi
  
  if [ "$skipReplace" = true ]; then
    # This value has to be passed over to import.sh on Dest
    skipReplace='--skip-replace'
  fi  

  if [ "$skipNetworkImport" = true ]; then
    # This value has to be passed over to export.sh on Src
    skipNetworkImport='--skip-network-import'
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
  # Setting Defaults
  local propertiesFile='db.properties'
  local batchLimit=10
  local poolLimit=7000
  local mergeBatchLimit=7000
  local waitTime=3
  local importWaitTime=180

  setGlobalVariables
  # Update options based on user's arguments
  parseArgs $@
  checkFlags
  echo ""
  echo "Starting to execute mirror_db."
  echo "##############################"
  echo "Current time: $(date)"

  setFilePermissions
  # Create logsDir if doesn't exist
  mkdir -p $logsDir

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

  if [ ! -z $dest ]; then
		echo "Executing upload_import script"
		uploadImportMain
  fi
  exit
}

mirrorDbMain $@