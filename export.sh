#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
POOL_WAIT_TIME=300
LOGS_DIR='log'
PI_TOTAL_FILE='pi_total.txt'

. parse_arguments.sh

DB_FILE_EXT=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $2}'`
DB_FILE_N=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}'`
NETWORK_DB="${DB_FILE_N}_network.${DB_FILE_EXT}"

LIST_FILE_EXT=`echo ${LIST_FILE_NAME} | sed 's/\./ /g' | awk '{print $2}'`
LIST_FILE_N=`echo ${LIST_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}'`
NETWORK_LIST="${LIST_FILE_N}_network.${LIST_FILE_EXT}"

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
BATCH_COUNT=1
POOL_COUNT=1
PI_TOTAL=1

for DBTB in `cat ${LIST_FILE_NAME}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`   
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`

    # Export only network tables from source
    if [[ $TB =~ wp_[a-z|A-z]+[a-zA-Z0-9_]* ]]; then
        if [ ${POOL_COUNT} -eq 1 ]
        then
            echo "Starting a new pool of downloads... "
        fi
        if [ ${BATCH_COUNT} -eq 1 ]
        then
            echo "Starting new batch of downloads... "
        fi
        echo "Dowloading ${TB}.sql ... "
        mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
        (( BATCH_COUNT++ ))
        (( POOL_COUNT++ ))
        (( TOTAL++ ))

        echo "${DB}.${TB}" >> ${NETWORK_LIST}
        
        if [ ${BATCH_COUNT} -eq ${BATCH_LIMIT} ]
        then
            BATCH_COUNT=1
            echo "Waiting to start new batch... "
            sleep $WAIT_TIME
        fi
        if [ ${POOL_COUNT} -eq ${POOL_LIMIT} ]
        then
            POOL_COUNT=1
            echo "Waiting to start new pool... "
            sleep $POOL_WAIT_TIME
        fi
    else
        echo "${DB}.${TB}" >> temp.txt
    fi
done

echo "Completed downloading Network tables..."

rm ${LIST_FILE_NAME}
mv temp.txt ${LIST_FILE_NAME}

if [ "$PARALLEL_IMPORT" = true ]; then
    echo "Executing parallel-import for network tables... "
    # Get to root dir
    cd ..

    # Initiate merging and importing all network tables
    nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_network.log 2>&1 

    # Continue exporting in BACKUP_DIR
    cd ${BACKUP_DIR}

fi    

echo "Starting to download all site tables... "

for DBTB in `cat ${LIST_FILE_NAME}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`   
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    
    if [ ${POOL_COUNT} -eq 1 ]; then
        echo "Starting a new pool of downloads... "
    fi
    if [ ${BATCH_COUNT} -eq 1 ]; then
        echo "Starting new batch of downloads... "
    fi
    echo "Dowloading ${TB}.sql ... "
    mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    (( BATCH_COUNT++ ))
    (( POOL_COUNT++ ))
    (( TOTAL++ ))

    if [ "$PARALLEL_IMPORT" = true ]; then
        echo "${DB}.${TB}" >> ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT}
    fi

    if [ ${BATCH_COUNT} -eq ${BATCH_LIMIT} ]; then
            BATCH_COUNT=1
        echo "Waiting to start new batch... "
        sleep $WAIT_TIME
    fi
    if [ ${POOL_COUNT} -eq ${POOL_LIMIT} ]; then
        if [ "$PARALLEL_IMPORT" = true ]; then
            # Get to root dir
            cd ..
            
            PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"

            nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1

            # Continue exporting in BACKUP_DIR
            cd ${BACKUP_DIR}
        fi
        POOL_COUNT=1
        (( PI_TOTAL++ ))
        echo "Waiting to start new pool... "
        sleep $POOL_WAIT_TIME
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${BATCH_COUNT} -gt 0 ]; then
    sleep 2
fi

# Get to root dir
cd ..

if [ ! "$PARALLEL_IMPORT" = true ]; then
    echo "Executing merge script for network tables... "
    # Merge all network tables to one mysql_network.sql
    ./merge.sh -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} -mbl ${MERGE_BATCH_LIMIT}

    echo "Executing merge script for all site tables... "
    # Merge all other tables to one mysql.sql
    ./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
else
    # Write PI_TOTAL value in PI_TOTAL_FILE to indicate the last merged sql file
    echo PI_TOTAL=${PI_TOTAL} > ${BACKUP_DIR}/${PI_TOTAL_FILE}
fi