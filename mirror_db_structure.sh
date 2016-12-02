#!/bin/bash

# Config Options
ARG1=$1
EXPORT_DIR=${2:-'db_export'}
IMPORT_SCRIPT='import.sh'
GET_DB_SCRIPT='get_db.sh'
SEARCH_REPLACE_SCRIPT='search_replace.sh'
DROP_SQL_FILE='drop_tables'
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
	echo ''
	echo "Attempting to remove all old script files if exists on server"
	rm $IMPORT_SCRIPT $GET_DB_SCRIPT $SEARCH_REPLACE_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql

elif [ "$ARG1" == "rm" ]; then
	rm $IMPORT_SCRIPT $GET_DB_SCRIPT $SEARCH_REPLACE_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql 
fi

