#!/bin/bash

. utilityFunctions.sh

uploadExportMain() {
  readProperties $src

  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "

  # Executing export at source
  if [ ! "$parallelImport" = true ]; then
    createRemoteScriptDir $src
    echo "Start Upload Export Process..."
    now=$(date +"%T")
    echo "Start time : $now "
    uploadMirrorDbFiles $src
    # TODO: Use screen for waiting while src performs export to avoid broken pipe
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${remoteScriptDir}; ./${exportScript} -s ${src} -d ${dest} -ebl ${batchLimit} -pl ${poolLimit} -mbl ${mergeBatchLimit} -ewt ${waitTime} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} --parallel-import ${networkFlag} --blog-id ${blogId};"

    if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${DB_BACKUP_DIR} ]" ); then
      # Get path for source db relative to DB_BACKUP_DIR
      DB_FILE_N=$(getFileName $DB_FILE_NAME)
      # Get absolute path for DB_BACKUP_DIR_PATH
      local sourceDbBackup=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}; cd ${DB_FILE_N}; pwd")
    fi

    # Get exported db from src to mirror_db server
    echo "Downloading database files from $src"
    getDb $sourceDbBackup
    removeMirrorDbFiles $src
    echo "Upload Export completed..."
    now=$(date +"%T")
    echo "End time : $now "

    # Exit if all tables are exported
    if [ "$parallelImport" = true ] || [ "$parallelImport" == '--parallel-import' ]; then
      echo "No more tables to export. Exiting... "
      exit
    fi
  else
  echo "Skipped Export Process..."
  fi
}