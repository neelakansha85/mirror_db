#!/bin/bash

set -e

. utilityFunctions.sh
. merge.sh

readonly EXPORT_DIR='db_export'
readonly POOL_WAIT_TIME=300
readonly LOGS_DIR='log'
readonly PI_TOTAL_FILE='pi_total.txt'

checkCount() {
  local count=$1
  local set=$2
  if [ ${count} -eq 1 ]; then
    echo "Starting new $set of downloads... "
  fi
}
#NOTE: to be changed: sleep pool_wait_time
checkCountLimit() {
  local count=$1
  local limit=$2
  if [ ${count} -eq ${limit} ]; then
    sleep $WAIT_TIME
    echo "1"
  else
    echo $count
  fi
}

dwnldTables() {
  local poolCount=1
  local batchCount=1
  local listFileName=$1
  for dbtb in $(cat ${listFileName})
  do
    db=$(getDbName $dbtb)
    tb=$(getTbName $dbtb)
    checkCount $poolCount "Pool"
    checkCount $batchCount "Batch"
    echo "Downloading ${tb}.sql ... "

    mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${db} ${tb} | gzip > ${db}_${tb}.sql.gz &
    (( batchCount++ ))
    (( poolCount++ ))
    (( total++ ))
    batchCount=$(checkCountLimit $batchCount $BATCH_LIMIT)
    #NOTE: to be changed: sleep pool_wait_time
    poolCount=$(checkCountLimit $poolCount $POOL_LIMIT)
  done

  echo "Completed downloading tables from $listFileName ..."
  echo "Total no of tables downloaded = ${total}"
  now=$(date +"%T")
  echo "Current time : $now "

  if [ ${batchCount} -gt 0 ]; then
    sleep 2
  fi
}

#starts here
exportMain() {

  parseArgs $@
  # scope of total is limited to exportMain()
  local total=1
  local PI_TOTAL=1

  FILE_EXT=$(getFileExtension $DB_FILE_NAME)
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

  echo "Starting to download DB... "
  now=$(date +"%T")
  echo "Current time : $now "

  if [ ! -z "$BLOG_ID" ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_${BLOG_ID}+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_blog
    dwnldTables ${LIST_FILE_NAME}_blog
    mergeMain -lf ${LIST_FILE_NAME}_blog -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}

  elif [ "$NETWORK_FLAG" = true ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_network
    dwnldTables ${LIST_FILE_NAME}_network
    mergeMain -lf ${LIST_FILE_NAME}_network -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}

  else
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_network
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_allothers
    dwnldTables ${LIST_FILE_NAME}_network
    mergeMain -lf ${LIST_FILE_NAME}_network -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
    dwnldTables ${LIST_FILE_NAME}_allothers
    mergeMain -lf ${LIST_FILE_NAME}_allothers -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
  fi
}


#########################################################################################################################
exportParallelMain() {
  parseArgs $@
  # scope of total is limited to exportMain()
  local total=1
  local PI_TOTAL=1

  FILE_EXT=$(getFileExtension $DB_FILE_NAME)
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

  echo "Starting to download DB... "
  now=$(date +"%T")
  echo "Current time : $now "

  if [ ! -z "$BLOG_ID" ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_${BLOG_ID}+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_blog
    #dwnldTables ${LIST_FILE_NAME}_blog
    #mergeMain -lf ${LIST_FILE_NAME}_blog -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}

  elif [ "$NETWORK_FLAG" = true ]; then
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_network
    #dwnldTables ${LIST_FILE_NAME}_network
    #mergeMain -lf ${LIST_FILE_NAME}_network -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}

  else
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_network
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > ${LIST_FILE_NAME}_allothers
    #dwnldTables ${LIST_FILE_NAME}_network
    #mergeMain -lf ${LIST_FILE_NAME}_network -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
    #dwnldTables ${LIST_FILE_NAME}_allothers
    #mergeMain -lf ${LIST_FILE_NAME}_allothers -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
  fi
  #downloading only network tables; same function is called because there are no changes.
  dwnldTables ${LIST_FILE_NAME}_network

  #removed if condition
  echo "Executing parallel-import for network tables... "
  # Get to root dir
  cd ..
  # Initiate merging and importing all network tables
  nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_network.log 2>&1
  # Continue exporting in EXPORT_DIR
  cd ${EXPORT_DIR}


  local poolCount=1
  local batchCount=1
  #this LIST_FILE_NAME should be LIST_FILE_NAME_blog or LIST_FILE_NAME_allother
  #so a function can be made for it eg dwnldTablesPI
  for dbtb in $(cat ${LIST_FILE_NAME})
  do
    db=$(getDbName $dbtb)
    tb=$(getTbName $dbtb)
    checkCount $poolCount "Pool"
    checkCount $batchCount "Batch"
    echo "Downloading ${tb}.sql ... "

    mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${db} ${tb} | gzip > ${db}_${tb}.sql.gz &
    (( batchCount++ ))
    (( poolCount++ ))
    (( total++ ))

    #removed if condition
    echo "${db}.${tb}" >> ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT}


    batchCount=$(checkCountLimit $batchCount $BATCH_LIMIT)
    if [ ${poolCount} -eq ${POOL_LIMIT} ]; then
      #removed if condition
      # Get to root dir
      cd ..
      PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"
      nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1
      # Continue exporting in EXPORT_DIR
      cd ${EXPORT_DIR}

      poolCount=1
      (( PI_TOTAL++ ))
      echo "Waiting to start new pool... "
      sleep $POOL_WAIT_TIME
    fi
  done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${total}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${batchCount} -gt 0 ]; then
  sleep 2
fi

# Get to root dir
cd ..
#if condition removed
# Execute merge and upload for the last set of tables downloaded
PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"
nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import --is-last-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1
}

exportMain
exportParallelMain