#!/bin/bash

BATCH_LIMIT=10
POOL_LIMIT=7000
MERGE_BATCH_LIMIT=7000
WAIT_TIME=3
IMPORT_WAIT_TIME=180
LIST_FILE_NAME='table_list.txt'
DB_FILE_NAME="mysql_$(date +"%Y-%m-%d")"
SRC_URL="''"
SRC_SHIB_URL="''"
SRC_G_ANALYTICS="''"
LOGS_DIR='log'

. parse_arguments.sh

if [ ! -d "$LOGS_DIR" ]; then
	mkdir $LOGS_DIR
fi

if [ "$SKIP_IMPORT" = true ]; then
	SKIP_IMPORT='--skip-import'
fi

if [ "$DROP_TABLES" = true ]; then
	DROP_TABLES='--drop-tables'
fi

if [ "$DROP_TABLES_SQL" = true ]; then
	DROP_TABLES='--drop-tables-sql'
fi

if [ "$PARALLEL_IMPORT" = true ]; then
	PARALLEL_IMPORT='--parallel-import'
fi

#set status to default 0
status=0

if [ ! -z $SRC ]; then
	if [ ! "$SKIP_EXPORT" = true ]; then
		DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d")"
		echo "Executing db export script"
		./export.sh -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${PARALLEL_IMPORT}
	fi
	if [ "$PARALLEL_IMPORT" = true ]; then
		 # Merge all tables to one mysql.sql
    	./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT} ${PARALLEL_IMPORT}
	fi
	. read_properties.sh $SRC

	SRC_URL=$URL
	SRC_SHIB_URL=$SHIB_URL
	SRC_G_ANALYTICS=$G_ANALYTICS
	
	#check execution status of export script
	status=$?
fi

if [ ! -z $DEST ]; then
	if [[ $status == 0 ]]; then
		echo "Executing upload_import script"
		./upload_import.sh -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} --site-url ${SRC_URL} --shib-url ${SRC_SHIB_URL} --g-analytics ${SRC_G_ANALYTICS} ${SKIP_IMPORT} ${FORCE_IMPORT} ${PARALLEL_IMPORT} ${DROP_TABLES} ${DROP_TABLES_SQL}
	else
		echo "Import process did not complete successfully"
	fi
fi

exit