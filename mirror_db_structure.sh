#!/bin/bash

# Config Options
ARG1=$1
BACKUP_DIR=${2:-'db_backup'}
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
PROPERTIES_FILE='db.properties'

if [ "$ARG1" == "mk" ]; then
	
	if [ ! -d "$BACKUP_DIR" ]; then	  
	  mkdir $BACKUP_DIR
	else
		# Remove all .sql files from previous run if any
		echo "Emptying ${BACKUP_DIR} dir..."
		rm -rf $BACKUP_DIR
		mkdir $BACKUP_DIR		
	fi

	# Remove all bash scripts from previous run if any
	echo ''
	echo "Attempting to remove all old script files if exists on server"
	rm $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql

elif [ "$ARG1" == "rm" ]; then
	rm $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql
fi

