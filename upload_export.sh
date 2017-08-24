#!/bin/bash

. utilityFunctions.sh

uploadExportMain() {
  readProperties $SRC

  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "

  if [ "$NETWORK_FLAG" = true ]; then
    local networkFlag='--network-flag'
  fi
  if [ "$PARALLEL_IMPORT" = true ]; then
    local parallelFlag='--parallel-import'
  fi
 #ideally there is no need to check pi here, since it will be called just once and after that
  # Executing export at source
 # if [ ! "$PARALLEL_IMPORT" = true ]; then
    createRemoteScriptDir $SRC
    echo "Start Upload Export Process..."
    now=$(date +"%T")
    echo "Start time : $now "
    uploadMirrorDbFiles $SRC
  #if not PI
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${parallelFlag} ${networkFlagG} --blog-id ${BLOG_ID};"

    # Get path for source db relative to DB_BACKUP_DIR
    DB_FILE_N=$(getFileName $DB_FILE_NAME)
    
    if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${DB_BACKUP_DIR}/${DB_FILE_N} ]" ); then
      # Get absolute path for DB_BACKUP_DIR_PATH
      local sourceDbBackup=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}/${DB_FILE_N}; pwd")
    fi

    # Get absolute path for MERGED_DIR in DB_BACKUP_DIR doesn't exist
    if [ -z sourceDbBackup ]; then
      local sourceDbBackup=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/${MERGED_DIR}; pwd")
    fi

    # Get exported db from SRC to mirror_db server
    echo "Removing all previous *.sql files if present and downloading database files from $SRC"
    getDb $sourceDbBackup
    removeMirrorDbFiles $SRC
    echo "Upload Export completed..."
    now=$(date +"%T")
    echo "End time : $now "

  #else
    # Exit if all tables are exported
    #if [ "$PARALLEL_IMPORT" = true ] || [ "$PARALLEL_IMPORT" == '--parallel-import' ]; then
    #capture signal
     # getDb
      #else echo "No more tables to export. Exiting... "
      #exit
    #fi
  #  echo "Skipped Export Process..."
 # fi
}
