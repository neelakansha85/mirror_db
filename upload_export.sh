#!/bin/bash

. utilityFunctions.sh

uploadExportMain() {
  readProperties $SRC

  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "

  # Executing export at source
  if [ ! "$PARALLEL_IMPORT" = true ]; then
    createRemoteScriptDir $SRC
    echo "Start Upload Export Process..."
    now=$(date +"%T")
    echo "Start time : $now "
    uploadMirrorDbFiles $SRC
    # TODO: Use screen for waiting while SRC performs export to avoid broken pipe
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${NETWORK_FLAG} --blog-id ${BLOG_ID};"

    if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${DB_BACKUP_DIR} ]" ); then
      # Get path for source db relative to DB_BACKUP_DIR
      DB_FILE_N=$(getFileName $DB_FILE_NAME)
      # Get absolute path for DB_BACKUP_DIR_PATH
      local sourceDbBackup=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}; cd ${DB_FILE_N}; pwd")
    fi

    # Get exported db from SRC to mirror_db server
    echo "Downloading database files from $SRC"
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