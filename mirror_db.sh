#!/bin/bash

BATCH_LIMIT=10
POOL_LIMIT=7000
MERGE_BATCH_LIMIT=7000
WAIT_TIME=3
IMPORT_WAIT_TIME=180
LIST_FILE_NAME='table_list.txt'
DB_FILE_NAME="mysql_$(date +"%Y-%m-%d").sql"
SRC_URL="''"
SRC_SHIB_URL="''"
SRC_G_ANALYTICS="''"
LOGS_DIR='log'
SRC_DB_BACKUP="''"
export SRC_DB_BACKUP

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
    echo "FAILURE: Error parsing arguments!"
    exit 1
fi

if [ ! -d "$LOGS_DIR" ]; then
	mkdir $LOGS_DIR
fi

if [ "$DROP_TABLES" = true ]; then
	DROP_TABLES='--drop-tables'
fi

if [ ! -z $DB_BACKUP ]; then
    SKIP_EXPORT=true
fi

if [ "$SKIP_EXPORT" = true ]; then
	SKIP_EXPORT='--skip-export'
	SRC_DB_BACKUP=${DB_BACKUP}
fi

if [ "$SKIP_IMPORT" = true ]; then
	SKIP_IMPORT='--skip-import'
	# Cannot drop entire database if skipping import process
	DROP_TABLES=
	DROP_TABLES_SQL=
fi

if [ "$SKIP_NETWORK_IMPORT" = true ]; then
	SKIP_NETWORK_IMPORT='--skip-network-import'
fi

if [ "$SKIP_REPLACE" = true ]; then
	SKIP_REPLACE='--skip-replace'
fi

if [ "$DROP_TABLES_SQL" = true ]; then
	DROP_TABLES_SQL='--drop-tables-sql'
fi

if [ "$PARALLEL_IMPORT" = true ]; then
	PARALLEL_IMPORT='--parallel-import'
	# Cannot drop entire database if running parallel-import
	DROP_TABLES=
	DROP_TABLES_SQL=
fi

if [ "$IS_LAST_IMPORT" = true ]; then
	IS_LAST_IMPORT='--is-last-import'
fi

echo ""
echo "Starting to execute mirror_db."
echo "##############################"
echo "Current time: $(date)"

# Changing right permissions for all bash scripts
echo "Changing right permissions for all bash scripts"
chmod 750 *.sh

#set status to default 0
status=0

if [ -e "$PROPERTIES_FILE" ]; then
	echo "--properties-file option is set"
	echo "Copying ${PROPERTIES_FILE} to db.properties file in current dir"
	cat $PROPERTIES_FILE > db.properties
fi

if [ ! -z $SRC ]; then
	
	DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d").sql"
	echo "Executing db export script"

	#added . ahead of calling child script to return the values back to parent script
	. ./upload_export.sh -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${PARALLEL_IMPORT} ${SKIP_EXPORT} 

	if [[ ! $? == 0 ]]; then
		echo "FAILURE: Error executing upload export script!"
		exit 1
	fi
	
	# Exit if all tables are exported
	if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
		echo "No more tables to export. Exiting... "
		exit
	fi

	if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
		# Merge all tables to one mysql.sql
    	echo "Executing merge script"
    	./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT} ${PARALLEL_IMPORT}
    	if [[ ! $? == 0 ]]; then
			echo "FAILURE: Error executing merge script!"
			exit 1
		fi
	fi
	
	. read_properties.sh $SRC
	if [[ ! $? == 0 ]]; then
	    echo "FAILURE: Error reading properties!"
	    exit 1
	fi

	SRC_URL=$URL
	SRC_SHIB_URL=$SHIB_URL
	SRC_G_ANALYTICS=$G_ANALYTICS
	
	#check execution status of export script
	status=$?
fi

if [ ! -z $DB_BACKUP ]; then
    echo "No alternate for database path found"
    SRC_DB_BACKUP="''"
fi

if [ ! -z $DEST ]; then
	if [[ $status == 0 ]]; then
		echo "Executing upload_import script"
		./upload_import.sh -s ${SRC} -d ${DEST} -dbf ${DB_FILE_NAME} --db-backup ${SRC_DB_BACKUP} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${PARALLEL_IMPORT} ${IS_LAST_IMPORT} ${DROP_TABLES} ${DROP_TABLES_SQL} ${SKIP_NETWORK_IMPORT} ${SKIP_REPLACE}
		if [[ ! $? == 0 ]]; then
			echo "FAILURE: Error executing upload import script!"
			exit 1
		fi
	else
		echo "Import process did not complete successfully"
	fi
fi

exit