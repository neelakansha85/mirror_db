#!/bin/bash

mirrorDbStructure() {
  # Config Options
  ARG1=$1
  EXPORT_DIR=${2:-'db_export'}
  IMPORT_SCRIPT='import.sh'
  DROP_SQL_FILE='drop_tables'
  SUPER_ADMIN_TXT='superadmin_dev.txt'
  PROPERTIES_FILE='db.properties'

  if [ "$ARG1" == "mk" ]; then
	  if [ ! -d "$EXPORT_DIR" ]; then
	    mkdir $EXPORT_DIR
	  else
		  # Remove all .sql files from previous run if any
		  echo "Emptying ${EXPORT_DIR} dir..."
		  rm -rf $EXPORT_DIR
		  mkdir $EXPORT_DIR
	  fi

	  # Remove all bash scripts from previous run if any
	  echo "Attempting to remove all old script files if exists on server"
	  rm -f $IMPORT_SCRIPT $PROPERTIES_FILE $DROP_SQL_FILE.sql $SUPER_ADMIN_TXT

  elif [ "$ARG1" == "rm" ]; then
	  rm -f $IMPORT_SCRIPT $PROPERTIES_FILE $DROP_SQL_FILE.sql $SUPER_ADMIN_TXT
  fi
}

mirrorDbStructure $@
