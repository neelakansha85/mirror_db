#!/bin/bash

# Config/Default Options
REMOTE_SCRIPT_DIR='mirror_db'
BACKUP_DIR='db_backup'
MERGED_DIR='db_merged'
ARCHIVES_DIR='db_archives'
DB_SUFFIX=''

. parse_arguments.sh

DB_FILE_EXT=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $2}'`
DB_FILE_N=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}'`


cd ${BACKUP_DIR}

if [ ! -d "$MERGED_DIR" ]; then
    mkdir $MERGED_DIR
fi

echo "Starting to merge DB to ${DB_FILE_NAME}... "
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
    
    MERGED_DB_FILE_NAME="${DB_FILE_N}${DB_SUFFIX}.${DB_FILE_EXT}"

    `cat ${DB}_${TB}.sql >> ${MERGED_DB_FILE_NAME}`
	echo "" >> ${MERGED_DB_FILE_NAME}
	`rm ${DB}_${TB}.sql`
	(( MERGE_BATCH_COUNT++ ))
    if [ ${MERGE_BATCH_COUNT} -eq ${MERGE_BATCH_LIMIT} ]; then
        mv ${MERGED_DB_FILE_NAME} $MERGED_DIR/${MERGED_DB_FILE_NAME}
        MERGE_BATCH_COUNT=1
        (( TOTAL++ ))
        echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
    fi
done

if [ -e ${MERGED_DB_FILE_NAME} ]; then
    mv ${MERGED_DB_FILE_NAME} $MERGED_DIR/${MERGED_DB_FILE_NAME}
fi

echo "Completed merging DB to ${DB_FILE_NAME}... "
echo "Total no of merged sql files = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

# Get to Home Dir
cd ~

# Move all .sql files to archives dir for future reference

if [ ! -d "${ARCHIVES_DIR}" ]; then
	mkdir ${ARCHIVES_DIR}
fi

cd ${ARCHIVES_DIR}

if [[ $DB_FILE_N =~ .*_network.* ]]; then
     DB_FILE_N=`echo ${DB_FILE_N} | cut -d '_' -f-2`
fi

if [ ! -d "${DB_FILE_N}" ]; then
     mkdir ${DB_FILE_N}
fi

# Get to Home Dir
cd ..

echo "Copying all merged DB files to archives dir... "

for MRDB in `ls ${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/${MERGED_DIR}/*.sql`
do
    cp ${MRDB} ${ARCHIVES_DIR}/${DB_FILE_N}/
done
