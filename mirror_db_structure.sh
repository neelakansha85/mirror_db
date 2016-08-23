#!/bin/bash

# Config Options
ARG1=$1
REMOTE_DIR=${2:-'mirror_db'}
BACKUP_DIR=${3:-'db_backup'}
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
PROPERTIES_FILE='db.properties'

# Move mysql.sql to archives with current date
if [ "$ARG1" == "mk" ]; then
	
	if [ ! -d "$REMOTE_DIR" ]; then
	  mkdir $REMOTE_DIR
	fi

	cd $REMOTE_DIR
	if [ ! -d "$BACKUP_DIR" ]; then	  
	  mkdir $BACKUP_DIR
	else
		# Remove all .sql files from previous run if any
		cd $BACKUP_DIR
		echo ''
		echo "Attempting to remove all .sql files if exists in ${BACKUP_DIR}"
		rm *.sql
		cd ..
	fi

	# Remove all bash scripts from previous run if any
	echo ''
	echo "Attempting to remove all bash files if exists in ${REMOTE_DIR}"
	rm $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql

	#chmod 775 $REMOTE_DIR $REMOTE_DIR/$BACKUP_DIR

elif [ "$ARG1" == "rm" ]; then
	cd $REMOTE_DIR
	rm $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $DROP_SQL_FILE.sql
fi

