#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
POOL_LIMIT=7000
POOL_WAIT_TIME=300

. parse_arguments.sh

# import instance environment variables
. read_properties.sh $SRC

# Empty BACKUP_DIR dir to remove any previous data
rm -rf ${BACKUP_DIR}
mkdir ${BACKUP_DIR}

cd ${BACKUP_DIR}

mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}'" > ${LIST_FILE_NAME}

echo "Starting to download DB... "
now=$(date +"%T")
echo "Current time : $now "

TOTAL=1
BATCH_COUNT=0
POOL_COUNT=0

for DBTB in `cat ${LIST_FILE_NAME}`
do
    if [ ${POOL_COUNT} -eq 0 ]
    then
        echo "Starting a new pool of downloads... "
    fi
    if [ ${BATCH_COUNT} -eq 0 ]
    then
        echo "Starting new batch of downloads... "
    fi
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`   
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    echo "Dowloading ${TB}.sql ... "
    mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    (( BATCH_COUNT++ ))
    (( POOL_COUNT++ ))
    (( TOTAL++ ))
    if [ ${BATCH_COUNT} -eq ${BATCH_LIMIT} ]
    then
        BATCH_COUNT=0
        echo "Waiting to start new batch... "
        sleep $WAIT_TIME
    fi
    if [ ${POOL_COUNT} -eq ${POOL_LIMIT} ]
    then
        POOL_COUNT=0
        echo "Waiting to start new pool... "
        sleep $POOL_WAIT_TIME
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${BATCH_COUNT} -gt 0 ]
then
    sleep 2
fi

# Get to root dir
cd ..

# Merge all tables to one mysql.sql
./merge.sh ${LIST_FILE_NAME} ${DB_FILE_NAME}