#!/bin/bash

set -ex

. parse_arguments.sh
. read_properties.sh
. merge.sh

# Config Options

readonly EXPORT_DIR='db_export'
readonly POOL_WAIT_TIME=300
readonly LOGS_DIR='log'
readonly PI_TOTAL_FILE='pi_total.txt'

dwnldNetworkTables() {
for dbtb in $(cat ${LIST_FILE_NAME})
do
     db=$(getDbName $dbtb)
     tb=$(getTbName $dbtb)

    # Export only network tables from source
    if [[ $tb =~ ^wp_[a-zA-Z]+[a-zA-Z0-9_]* ]]; then
        checkPoolCount
        checkBatchCount
        downloadTables
        echo "${db}.${tb}" >> ${NETWORK_LIST}
        checkBatchLimit
        checkPoolLimit
    else
        echo "${db}.${tb}" >> temp.txt
    fi
done

echo "Completed downloading Network tables..."
}

checkPoolCount(){
        if [ ${pool_count} -eq 1 ]
        then
            echo "Starting a new pool of downloads... "
        fi
        }
checkBatchCount(){
         if [ ${batch_count} -eq 1 ]
        then
            echo "Starting new batch of downloads... "
        fi
}
downloadTables(){
        echo "Downloading ${tb}.sql ... "
        mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${db} ${tb} | gzip > ${db}_${tb}.sql.gz &
        (( batch_count++ ))
        (( pool_count++ ))
        (( total++ ))
}

checkBatchLimit(){
        if [ ${batch_count} -eq ${BATCH_LIMIT} ]
        then
            batch_count=1
            echo "Waiting to start new batch... "
            sleep $WAIT_TIME
        fi
        }

checkPoolLimit(){
        if [ ${pool_count} -eq ${POOL_LIMIT} ]
        then
            pool_count=1
            echo "Waiting to start new pool... "
            sleep $POOL_WAIT_TIME
        fi
        }




#starts here
parseArgs $@

DB_FILE_EXT=$(getFileExtension $DB_FILE_NAME)
DB_FILE_N=$(getFileName $DB_FILE_NAME)
NETWORK_DB="${DB_FILE_N}_network.${DB_FILE_EXT}"

LIST_FILE_EXT=$(getFileExtension $LIST_FILE_NAME)
LIST_FILE_N=$(getFileName $LIST_FILE_NAME)
NETWORK_LIST="${LIST_FILE_N}_network.${LIST_FILE_EXT}"

# import instance environment variables
readProperties $SRC

# Empty EXPORT_DIR dir to remove any previous data
rm -rf ${EXPORT_DIR}
mkdir ${EXPORT_DIR}

cd ${EXPORT_DIR}
if [ "$NETWORK_FLAG" = true ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}

elif [ ! -z "$BLOG_ID" ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_${BLOG_ID}+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}

else
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}'" > ${LIST_FILE_NAME}
fi
echo "Starting to download DB... "
now=$(date +"%T")
echo "Current time : $now "
total=1
batch_count=1
pool_count=1
PI_TOTAL=1
dwnldNetworkTables


rm ${LIST_FILE_NAME}
mv temp.txt ${LIST_FILE_NAME}

if [ "$PARALLEL_IMPORT" = true ]; then
    echo "Executing parallel-import for network tables... "
    # Get to root dir
    cd ..

    # Initiate merging and importing all network tables
    nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_network.log 2>&1 

    # Continue exporting in EXPORT_DIR
    cd ${EXPORT_DIR}

fi    

echo "Starting to download all site tables... "

# Reset Counter for Batch and Pool limits
batch_count=1
pool_count=1

for dbtb in $(cat ${LIST_FILE_NAME})
do
     db=$(getDbName $dbtb)
     tb=$(getTbName $dbtb)
    
     checkPoolCount
     checkBatchCount
     downloadTables

    if [ "$PARALLEL_IMPORT" = true ]; then
        echo "${db}.${tb}" >> ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT}
    fi

     checkBatchLimit
    if [ ${pool_count} -eq ${POOL_LIMIT} ]; then
        if [ "$PARALLEL_IMPORT" = true ]; then
            # Get to root dir
            cd ..
            
            PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"

            nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1

            # Continue exporting in EXPORT_DIR
            cd ${EXPORT_DIR}
        fi
        pool_count=1
        (( PI_TOTAL++ ))
        echo "Waiting to start new pool... "
        sleep $POOL_WAIT_TIME
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${total}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${batch_count} -gt 0 ]; then
    sleep 2
fi

# Get to root dir
cd ..

if [ ! "$PARALLEL_IMPORT" = true ]; then
    echo "Executing merge script for network tables... "
    # Merge all network tables to one mysql_network.sql
    ./merge.sh -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} -mbl ${MERGE_BATCH_LIMIT}
    if [[ ! $? == 0 ]]; then
        echo "FAILURE: Error merging network tables in Parallel Import!"
        exit 1
    fi

    echo "Executing merge script for all site tables... "
    # Merge all other tables to one mysql.sql
    ./merge.sh -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
    if [[ ! $? == 0 ]]; then
        echo "FAILURE: Error merging all site tables in Parallel Import!"
        exit 1
    fi
else
    # Execute merge and upload for the last set of tables downloaded
    PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"
    nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import --is-last-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1
fi