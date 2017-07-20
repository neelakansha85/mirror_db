#!/bin/bash

set -e

. utilityFunctions.sh
. merge.sh

setExportGlobalVariables() {
  # These variables are shared between export.sh and merge.sh files
  readonly exportDir='db_export'
  readonly mergedDir='db_merged'
  readonly logsDir='log'
  readonly PiTotalFile='pi_total.txt'
  readonly poolWaitTime=300
}

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

    mysqldump --host=${dbHostName} --user=${dbUser} --password=${dbPassword} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${db} ${tb} | gzip > ${db}_${tb}.sql.gz &
    (( batchCount++ ))
    (( poolCount++ ))
    (( total++ ))
    batchCount=$(checkCountLimit $batchCount $batchLimit)
    #NOTE: to be changed: sleep pool_wait_time
    poolCount=$(checkCountLimit $poolCount $poolLimit $poolWaitTime)
  done
  (( total-- ))
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

    mysqldump --host=${dbHostName} --user=${dbUser} --password=${dbPassword} --default-character-set=utf8 --hex-blob --single-transaction --quick --triggers ${db} ${tb} | gzip > ${db}_${tb}.sql.gz &
    (( batchCount++ ))
    (( poolCount++ ))
    (( total++ ))

    # Required for identifying which file needs to be imported
    echo "${db}.${tb}" >> ${listFileName}_${piTotal}.${listFileExt}

    batchCount=$(checkCountLimit $batchCount $batchLimit)
    poolCount=$(checkCountLimit $poolCount $poolLimit $poolWaitTime)
    if [ ${poolCount} -eq 1 ]; then
      # TODO: Remove below line and cd {exportDir} if using absolute path for dir
      # Get to root dir
      cd ..
      dbFileNamePI="${dbFileName}_${piTotal}.${dbFileExt}"
      nohup ./mirror_db.sh -s ${src} -d ${dest} -lf ${listFileName}_${piTotal}.${listFileExt} -dbf ${dbFileNamePI} --skip-export --parallel-import >> ${logsDir}/mirror_db_pi.log 2>&1
      # Continue exporting in exportDir
      cd ${exportDir}
      (( piTotal++ ))
    fi
  done
  total=total-1
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
  mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${dbSchema}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${networkDb} -mbl ${mergeBatchLimit}
}

downloadBlogTables() {
  local listFileName=${1:-table_list.txt}
  mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${dbSchema}' AND TABLE_NAME REGEXP '^wp_${blogId}+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${blogDb} -mbl ${mergeBatchLimit}
}

downloadNonNetworkTables() {
  local listFileName=${1:-table_list.txt}
  mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${dbSchema}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > $listFileName
  downloadTables $listFileName
  mergeMain -lf $listFileName -dbf ${dbFile} -mbl ${mergeBatchLimit}
}

exportParallelMain() {
  # Starting Parallel Import
  # Download Network tables first
  # TODO: Verify if mergeMain() is required and if so use below function
  # downloadNetworkTables $networkListFile
  mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${dbSchema}' AND TABLE_NAME REGEXP '^wp_[a-zA-Z]+[a-zA-Z0-9_]*$'" > $networkListFile
  downloadTables $networkListFile
  # TODO: Need to verify if mergeMain() is required for Network tables
  # mergeMain -lf $networkListFile -dbf ${dbFile} -mbl ${mergeBatchLimit}
  echo "Executing parallel-import for network tables... "
  # TODO: Remove below line and cd {exportDir} if using absolute path for dir
  # Get to root dir
  cd ..
  # Initiate merging and importing all network tables
  nohup ./mirror_db.sh -s ${src} -d ${dest} -lf ${networkListFile} -dbf ${networkDb} --skip-export --parallel-import >> ${logsDir}/mirror_db_network.log 2>&1
  # Continue exporting in exportDir
  cd ${exportDir}
  # Download all Non Network Tables
  # TODO: Verify if mergeMain() is required and if so use below function
  # downloadNonNetworkTables $nonNetworkListFile
  mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${dbSchema}' AND TABLE_NAME REGEXP '^wp_[0-9]+[a-zA-Z0-9_]*$'" > $nonNetworkListFile
  downloadTablesPI $nonNetworkListFile
  # TODO: Need to verify if mergeMain() is required for Network tables
  # mergeMain -lf $nonNetworkListFile -dbf ${dbFile} -mbl ${mergeBatchLimit}
  
  # TODO: Remove below line and cd {exportDir} if using absolute path for dir
  # Get to root dir
  cd ..

  # Execute merge and upload for the last set of tables downloaded
  dbFileNamePI="${dbFileName}_${piTotal}.${dbFileExt}"
  nohup ./mirror_db.sh -s ${src} -d ${dest} -lf ${listFileName}_${piTotal}.${listFileExt} -dbf ${dbFileNamePI} --skip-export --parallel-import --is-last-import >> ${logsDir}/mirror_db_pi.log 2>&1
}

#starts here
exportMain() {

  # Set's global variables for the export process running on src server
  setExportGlobalVariables
  
  parseArgs $@
  
  # scope of total is limited to exportMain()
  local total=1
  local piTotal=1
  local dbFile=${DB_FILE_NAME}
  local listFile=${LIST_FILE_NAME}
  local dbFileExt=$(getFileExtension $dbFile)
  local dbFileName=$(getFileName $dbFile)
  local networkDb="${dbFileName}_network.${dbFileExt}"
  local blogDb="${dbFileName}_${blogId}.${dbFileExt}"
  local listFileExt=$(getFileExtension $listFile)
  local listFileName=$(getFileName $listFile)
  local networkListFile="${listFileName}_network.${listFileExt}"
  local blogListFile="${listFileName}_${blogId}.${listFileExt}"
  local nonNetworkListFile="${listFileName}_non_network.${listFileExt}"
  local remoteScriptDir='mirror_db'
  local dbSuffix=''

  # import instance environment variables
  readProperties $src

  # Empty exportDir dir to remove any previous data
  # TODO: Need to verify if it deletes export dir for 
  # Parallel Import which shouldn't happen
  rm -rf ${exportDir}
  mkdir ${exportDir}
  cd ${exportDir}

  echo "Starting to download DB... "
  now=$(date +"%T")
  echo "Current time : $now "

  if [ ! "$parallelImport" = true ]; then
    if [ ! -z "$blogId" ]; then
      downloadBlogTables $blogListFile
    elif [ "$networkFlag" = true ]; then
      downloadNetworkTables $networkListFile
    else
      downloadNetworkTables $networkListFile
     # total=$(getTotal)
      downloadNonNetworkTables $nonNetworkListFile
    fi
  else
    exportParallelMain
  fi

  # Checking back to root dir
  cd ..
}

exportMain $@