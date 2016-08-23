#!/bin/bash

# Config/Default Options
BACKUP_DIR='db_backup'
ARCHIVES_DIR='archives'
MERGE_BATCH_LIMIT=10000

. parse_arguments.sh

cd ${BACKUP_DIR}

echo "Starting to merge DB to ${DB_FILE_NAME}.sql... "
now=$(date +"%T")
echo "Current time : $now "

TOTAL=1
MERGE_BATCH_COUNT=1

for DBTB in `cat ${LIST_FILE_NAME}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    gunzip ${DB}_${TB}.sql.gz
    `cat ${DB}_${TB}.sql >> ${DB_FILE_NAME}_${TOTAL}.sql`
	echo "" >> ${DB_FILE_NAME}.sql
	`rm ${DB}_${TB}.sql`
	(( MERGE_BATCH_COUNT++ ))
	(( TOTAL++ ))
    if [ ${MERGE_BATCH_COUNT} -eq ${MERGE_BATCH_LIMIT} ]
    then
        MERGE_BATCH_COUNT=1
        echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
    fi
done

echo "Completed merging DB to ${DB_FILE_NAME}.sql... "
echo "Total no of merged sql files = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

# Get to root dir
cd ..

# Move all .sql files to archives dir for future reference

if [ ! -d "$ARCHIVES_DIR" ]; then
	mkdir $ARCHIVES_DIR
fi

cd ${BACKUP_DIR}
for MRDB in `ls *.sql`
do
	cp ${MRDB} ../${ARCHIVES_DIR}/${MRDB}
done
