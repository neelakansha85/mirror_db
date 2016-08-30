#!/bin/bash

# Config/Default Options
BACKUP_DIR='db_backup'
MERGED_DIR='db_merged'
ARCHIVES_DIR='archives'
DB_SUFFIX=''

. parse_arguments.sh

cd ${BACKUP_DIR}

if [ ! -d "$MERGED_DIR" ]; then
    mkdir $MERGED_DIR
fi

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
    
    if [ ! "$PARALLEL_IMPORT" = true ]; then
        DB_SUFFIX="_${TOTAL}"
    fi
    
    `cat ${DB}_${TB}.sql >> ${DB_FILE_NAME}${DB_SUFFIX}.sql`
	echo "" >> ${DB_FILE_NAME}${DB_SUFFIX}.sql
	`rm ${DB}_${TB}.sql`
	(( MERGE_BATCH_COUNT++ ))
    if [ ${MERGE_BATCH_COUNT} -eq ${MERGE_BATCH_LIMIT} ]; then
        mv ${DB_FILE_NAME}${DB_SUFFIX}.sql $MERGED_DIR/${DB_FILE_NAME}${DB_SUFFIX}.sql
        MERGE_BATCH_COUNT=1
        (( TOTAL++ ))
        echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
    fi
done

if [ -e ${DB_FILE_NAME}${DB_SUFFIX}.sql ]; then
    mv ${DB_FILE_NAME}${DB_SUFFIX}.sql $MERGED_DIR/${DB_FILE_NAME}${DB_SUFFIX}.sql
fi

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

cd ${BACKUP_DIR}/${MERGED_DIR}
for MRDB in `ls *.sql`
do
	cp ${MRDB} ../${ARCHIVES_DIR}/${MRDB}
done
