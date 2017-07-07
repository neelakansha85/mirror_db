#!/bin/bash

. utilityFunctions.sh

#starts here
uploadExportMain() {
  readProperties $SRC

  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "

  #executing export at source
  if [ ! "$SKIP_EXPORT" = true ]; then
    createRemoteScriptDir $SRC
    echo "Start Upload Export Process..."
    now=$(date +"%T")
    echo "Start time : $now "

    uploadMirrorDbFiles $SRC
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${PARALLEL_IMPORT} ${NETWORK_FLAG} --blog-id ${BLOG_ID};"

    if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${DB_BACKUP_DIR} ]" ); then
      # Get path for source db relative to DB_BACKUP_DIR
      DB_FILE_N=$(getFileName $DB_FILE_NAME)
      # Get absolute path for DB_BACKUP_DIR_PATH
      local sourceDbBackup=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}; cd ${DB_FILE_N}; pwd")
    fi

    # Get exported db from SRC to mirror_db server
    echo "Transferring files from SRC to mirror_db server"
    getDb $sourceDbBackup
    removeMirrorDbFiles $SRC
    echo "Upload Export completed..."
    now=$(date +"%T")
    echo "End time : $now "

    # Exit if all tables are exported
    if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
      echo "No more tables to export. Exiting... "
      exit
    fi
  else
  echo "Skipped Export Process..."
  fi
}