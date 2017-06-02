#!/bin/bash

set -e

. utilityFunctions.sh

# Config/Default Options
# TODO: make use of $(pwd) to get absolute path for below variables
readonly REMOTE_SCRIPT_DIR='mirror_db'
readonly EXPORT_DIR='db_export'
readonly MERGED_DIR='db_merged'
readonly DB_BACKUP_DIR='db_backup'
DB_SUFFIX=''

mergeFileName(){
  local total=$1
  if [ ! "$PARALLEL_IMPORT" = true ]; then
    DB_SUFFIX="_${total}"
  fi
  mergedName="${DB_FILE_N}${DB_SUFFIX}.${DB_FILE_EXT}"
  echo $mergedName
}

moveFileToMergeDir(){
  if [ -e ${mergedFileName} ]; then
    mv ${mergedFileName} $MERGED_DIR/${mergedFileName}
  fi
}

mergeFile(){
  echo "Starting to merge DB to ${DB_FILE_NAME}... "
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

    if [ ${mergeBatchCount} -eq ${MERGE_BATCH_LIMIT} ]; then
      moveFileToMergeDir
      mergeBatchCount=1
      (( total++ ))
      echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
    fi
  done
  moveFileToMergeDir
  echo "Completed merging DB to ${DB_FILE_NAME}... "
  echo "Total no of merged sql files = ${total}"
  now=$(date +"%T")
  echo "Current time : $now "
}

archiveMergedFiles(){
  echo "Copying all merged DB files to archives dir... "
  # TODO: Update path based on absolute path of the file using $(pwd)
  for mrdb in $(ls ${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/${MERGED_DIR}/*.sql)
  do
    cp ${mrdb} ${DB_BACKUP_DIR}/${DB_FILE_N}/
  done
}

mergeMain() {
  parseArgs $@

  DB_FILE_EXT=$(getFileExtension $DB_FILE_NAME)
  DB_FILE_N=$(getFileName $DB_FILE_NAME)

  cd ${EXPORT_DIR}
  mkdir -p $MERGED_DIR
  mergeFile

  # Get to Home Dir
  cd ~

  # Move all .sql files to archives dir for future reference
  mkdir -p $DB_BACKUP_DIR
  cd ${DB_BACKUP_DIR}

  if [[ $DB_FILE_N =~ .*_network.* ]]; then
    DB_FILE_N=$(echo ${DB_FILE_N} | cut -d '_' -f-2)
  fi

  mkdir -p $DB_FILE_N
  # TODO: Remove below line if using absolute path for dir
  # Get to Home Dir
  cd ..
  archiveMergedFiles
}
