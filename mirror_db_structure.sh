#!/bin/bash

mirrorDbStructure() {
  # Config Options
  ARG1=$1
  EXPORT_DIR=${2:-'db_export'}
  IMPORT_SCRIPT='import.sh'
  SEARCH_REPLACE_SCRIPT='search_replace.sh'
  AFTER_IMPORT_SCRIPT='after_import.sh'
  DROP_SQL_FILE='drop_tables'
  SUPER_ADMIN_TXT='superadmin_dev.txt'
  PARSE_FILE='parse_arguments.sh'
  READ_PROPERTIES_FILE='read_properties.sh'
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
	  rm -f $IMPORT_SCRIPT $SEARCH_REPLACE_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql ${SUPER_ADMIN_TXT} ${AFTER_IMPORT_SCRIPT}

  elif [ "$ARG1" == "rm" ]; then
	  rm -f $IMPORT_SCRIPT $SEARCH_REPLACE_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql ${SUPER_ADMIN_TXT} ${AFTER_IMPORT_SCRIPT}
  fi
}

mirrorDbStructure $@
