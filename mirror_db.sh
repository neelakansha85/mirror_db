#!/bin/bash

BATCH_LIMIT=10
WAIT_TIME=3
LIST_FILE_NAME='table_list.txt'
DB_FILE_NAME="mysql_$(date +"%Y-%m-%d")"
SRC_URL="''"
SRC_SHIB_URL="''"
SRC_G_ANALYTICS="''"
FORCE_IMPORT=""

. parse_arguments.sh

#set status to default 0
status=0

if [ ! -z $SRC ]; then
	echo "Executing db export script"
	./export.sh -s ${SRC} -bl ${BATCH_LIMIT} -wt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME}
	. read_properties.sh $SRC

	SRC_URL=$URL
	SRC_SHIB_URL=$SHIB_URL
	SRC_G_ANALYTICS=$G_ANALYTICS
	
	#check execution status of export script
	status=$?
fi

if [ ! -z $DEST ]; then
	if [[ $status == 0 ]]; then
		echo "Executing db import script"

		./upload_import.sh -d ${DEST} -dbf ${DB_FILE_NAME} -site-url ${SRC_URL} -shib ${SRC_SHIB_URL} -g-analytics ${SRC_G_ANALYTICS}
	else
		echo "Import process did not complete successfully"
	fi
fi

exit