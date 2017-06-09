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

checkCountLimit() {
  local count=$1
  local limit=$2
  local waitTime=${3:-3}
  if [ ${count} -eq ${limit} ]; then
    sleep $waitTime
    echo "1"
  else
    echo $count
  fi
}

downloadTables() {
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
    poolCount=$(checkCountLimit $poolCount $POOL_LIMIT $POOL_WAIT_TIME)
  done

  echo "Completed downloading tables from $listFileName ..."
  echo "Total no of tables downloaded = ${total}"
  now=$(date +"%T")
  echo "Current time : $now "
  if [ ${batchCount} -gt 0 ]; then
    sleep 2
  fi
}

# For downloading Non Network tables if Parallel Import is true
downloadTablesPI() {
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

    # Required for identifying which file needs to be imported
    echo "${db}.${tb}" >> ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT}

    batchCount=$(checkCountLimit $batchCount $BATCH_LIMIT)
    poolCount=$(checkCountLimit $poolCount $POOL_LIMIT $POOL_WAIT_TIME)
    if [ ${poolCount} -eq 1 ]; then
      # TODO: Remove below line and cd {EXPORT_DIR} if using absolute path for dir
      # Get to root dir
      cd ..
      PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"
      nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1
      # Continue exporting in EXPORT_DIR
      cd ${EXPORT_DIR}
      (( PI_TOTAL++ ))
    fi
  done
  echo "Completed downloading tables from ${listFileName}..."
  echo "Total no of tables downloaded = ${total}"
  now=$(date +"%T")
  echo "Current time : $now "
  if [ ${batchCount} -gt 0 ]; then
    sleep 2
  fi
}

downloadNetworkTables() {
  local listFileName=${1:-table_list.txt}
  mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
}

downloadBlogTables() {
  local listFileName=${1:-table_list.txt}
  mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_${BLOG_ID}+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
}

downloadNonNetworkTables() {
  local listFileName=${1:-table_list.txt}
  mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
}

exportParallelMain() {
  # Starting Parallel Import
  # Download Network tables first
  # TODO: Verify if mergeMain() is required and if so use below function
  # downloadNetworkTables $networkListFile
  mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > $networkListFile
  downloadTables $networkListFile
  # TODO: Need to verify if mergeMain() is required for Network tables
  # mergeMain -lf $networkListFile -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}
  echo "Executing parallel-import for network tables... "
  # TODO: Remove below line and cd {EXPORT_DIR} if using absolute path for dir
  # Get to root dir
  cd ..
  # Initiate merging and importing all network tables
  nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${NETWORK_LIST} -dbf ${NETWORK_DB} --skip-export --parallel-import >> ${LOGS_DIR}/mirror_db_network.log 2>&1
  # Continue exporting in EXPORT_DIR
  cd ${EXPORT_DIR}
  # Download all Non Network Tables
  # TODO: Verify if mergeMain() is required and if so use below function
  # downloadNonNetworkTables $nonNetworkListFile
  mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > $nonNetworkListFile
  downloadTablesPI $nonNetworkListFile
  # TODO: Need to verify if mergeMain() is required for Network tables
  # mergeMain -lf $nonNetworkListFile -dbf ${DB_FILE_NAME} -mbl ${MERGE_BATCH_LIMIT}  
  
  # TODO: Remove below line and cd {EXPORT_DIR} if using absolute path for dir
  # Get to root dir
  cd ..

  # Execute merge and upload for the last set of tables downloaded
  PI_DB_FILE_N="${DB_FILE_N}_${PI_TOTAL}.${DB_FILE_EXT}"
  nohup ./mirror_db.sh -s ${SRC} -d ${DEST} -lf ${LIST_FILE_N}_${PI_TOTAL}.${LIST_FILE_EXT} -dbf ${PI_DB_FILE_N} --skip-export --parallel-import --is-last-import >> ${LOGS_DIR}/mirror_db_pi.log 2>&1
}

#starts here
exportMain() {

  parseArgs $@
  # scope of total is limited to exportMain()
  local total=1
  local PI_TOTAL=1
  local networkListFile="${LIST_FILE_NAME}_network"
  local blogListFile="${LIST_FILE_NAME}_${BLOG_ID}"
  local nonNetworkListFile="${LIST_FILE_NAME}_non_network"

  FILE_EXT=$(getFileExtension $DB_FILE_NAME)
  DB_FILE_N=$(getFileName $DB_FILE_NAME)
  NETWORK_DB="${DB_FILE_N}_network.${DB_FILE_EXT}"

  LIST_FILE_EXT=$(getFileExtension $LIST_FILE_NAME)
  LIST_FILE_N=$(getFileName $LIST_FILE_NAME)
  NETWORK_LIST="${LIST_FILE_N}_network.${LIST_FILE_EXT}"

  # import instance environment variables
  readProperties $SRC

  # Empty EXPORT_DIR dir to remove any previous data
  # TODO: Need to verify if it deletes export dir for 
  # Parallel Import which shouldn't happen
  rm -rf ${EXPORT_DIR}
  mkdir ${EXPORT_DIR}
  cd ${EXPORT_DIR}

  echo "Starting to download DB... "
  now=$(date +"%T")
  echo "Current time : $now "

  if [ ! "$PARALLEL_IMPORT" = true ]; then
    if [ ! -z "$BLOG_ID" ]; then
      downloadBlogTables $blogListFile
    elif [ "$NETWORK_FLAG" = true ]; then
      downloadNetworkTables $networkListFile
    else
      downloadNetworkTables $networkListFile
      downloadNonNetworkTables $nonNetworkListFile
    fi
  else
    exportParallelMain
  fi
}

exportMain