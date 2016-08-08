#!/bin/bash

# Config Options
FILE_NAME_TABLST==${1:-table_list.txt}
DB_FILE_NAME==${2:-mysql}
BACKUP_DIR='db_backup'

cd ${BACKUP_DIR}

gunzip *.sql.gz

echo "Starting to merge DB to ${DB_FILE_NAME}.sql... "
now=$(date +"%T")
echo "Current time : $now "

for DBTB in `cat ${FILE_NAME_TABLST}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    `cat ${DB}_${TB}.sql >> ${DB_FILE_NAME}.sql`
	echo "" >> ${DB_FILE_NAME}
	`rm ${DB}_${TB}.sql`
done

echo "Completed merging DB to ${DB_FILE_NAME}.sql... "
now=$(date +"%T")
echo "Current time : $now "

# Get to root dir
cd ..

