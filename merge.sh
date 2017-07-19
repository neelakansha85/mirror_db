#!/bin/bash

set -e

. utilityFunctions.sh

mergeFileName(){
  local total=$1
  if [ ! "$PARALLEL_IMPORT" = true ]; then
    dbSuffix="_${total}"
  fi
  mergedName="${dbFileName}${dbSuffix}.${dbFileExt}"
  echo $mergedName
}

moveFileToMergeDir(){
  if [ -e ${mergedFileName} ]; then
    mv ${mergedFileName} $mergedDir/${mergedFileName}
  fi
}

mergeFile(){
  echo "Starting to merge DB to ${dbFile}... "
  now=$(date +"%T")
  echo "Current time : $now "

  total=1
  mergeBatchCount=1

  for dbtb in $(cat ${LIST_FILE_NAME})
  do
    db=$(getDbName $dbtb)
    tb=$(getTbName $dbtb)
    gunzip ${db}_${tb}.sql.gz

    mergedFileName=$(mergeFileName $total)

    $(cat ${db}_${tb}.sql >> ${mergedFileName})
    echo "" >> ${mergedFileName}
    $(rm ${db}_${tb}.sql)
    (( mergeBatchCount++ ))

    if [ ${mergeBatchCount} -eq ${mergeBatchLimit} ]; then
      moveFileToMergeDir
      mergeBatchCount=1
      (( total++ ))
      echo "Merged ${mergeBatchLimit} tables, starting new batch for merging... "
    fi
  done
  moveFileToMergeDir
  echo "Completed merging DB to ${dbFile}... "
  echo "Total no of merged sql files = ${total}"
  now=$(date +"%T")
  echo "Current time : $now "
}

archiveMergedFiles(){
  echo "Copying all merged DB files to archives dir... "
  # TODO: Update path based on absolute path of the file using $(pwd)
  for mrdb in $(ls ~/${remoteScriptDir}/${exportDir}/${mergedDir}/*.sql)
  do
    cp ${mrdb} ~/${DB_BACKUP_DIR}/${dbFileName}/
  done
}

mergeMain() {
  parseArgs $@

  local dbFile=${DB_FILE_NAME}
  local dbFileExt=$(getFileExtension $dbFile)
  local dbFileName=$(getFileName $dbFile)

  mkdir -p $mergedDir
  mergeFile

  # Move all .sql files to archives dir for future reference
  if [[ $dbFileName =~ .*_network.* ]]; then
    dbFileName=$(echo ${dbFileName} | cut -d '_' -f-2)
  fi

  mkdir -p ~/$DB_BACKUP_DIR/$dbFileName

  archiveMergedFiles
}
