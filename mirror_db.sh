#!/bin/bash

set -e

. utilityFunctions.sh
. upload_export.sh
. upload_import.sh

setGlobalVariables
parseArgs $@

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
	DB_BACKUP_DIR=${DB_BACKUP}
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

if [ "$NETWORK_FLAG" = true ]; then
	NETWORK_FLAG='--network-flag'
fi

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
	
	readProperties $SRC

	SRC_URL=$URL
	SRC_SHIB_URL=$SHIB_URL
	SRC_G_ANALYTICS=$G_ANALYTICS
	
fi

# TODO: Need to fix below condition $DB_BACKUP_DIR is now directly by putDb()
if [ -z $DB_BACKUP ]; then
    echo "No alternate for database path found"
    DB_BACKUP_DIR="''"
fi

if [ ! -z $DEST ]; then
		echo "Executing upload_import script"
		uploadImportMain
fi

exit