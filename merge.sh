#!/bin/bash

# Config Options
LIST_FILE_NAME=${1:-table_list.txt}
DB_FILE_NAME=${2:-mysql}
BACKUP_DIR='db_backup'
ARCHIVES_DIR='archives'

cd ${BACKUP_DIR}

echo "Starting to merge DB to ${DB_FILE_NAME}.sql... "
now=$(date +"%T")
echo "Current time : $now "

for DBTB in `cat ${LIST_FILE_NAME}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    gunzip ${DB}_${TB}.sql.gz
    `cat ${DB}_${TB}.sql >> ${DB_FILE_NAME}.sql`
	echo "" >> ${DB_FILE_NAME}.sql
	`rm ${DB}_${TB}.sql`
done

echo "Completed merging DB to ${DB_FILE_NAME}.sql... "
now=$(date +"%T")
echo "Current time : $now "

# Get to root dir
cd ..

# Move mysql.sql to archives with current date

if [ ! -d "$ARCHIVES_DIR" ]; then
  mkdir $ARCHIVES_DIR
fi

cp ${BACKUP_DIR}/${DB_FILE_NAME}.sql ${ARCHIVES_DIR}/${DB_FILE_NAME}.sql
