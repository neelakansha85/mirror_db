#!/bin/bash

. utilityFunctions.sh

prepareForExport() {
  createRemoteScriptDir $SRC
  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "
  uploadMirrorDbFiles $SRC
  # TODO: Use screen for waiting while SRC performs export to avoid broken pipe
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${networkFlag} --blog-id ${BLOG_ID};"

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
}

prepareForExport_PI() {
  # TODO: Rewrite export process using Parallel Import functionality
  
  # Exit if all tables are exported
  if [ "$IS_LAST_IMPORT" = true ]; then
    echo "No more tables to export. Exiting... "
    exit
  fi
}

uploadExportMain() {
  readProperties $SRC

  echo "Start Upload Export Process..."
  now=$(date +"%T")
  echo "Start time : $now "

  if [ "$NETWORK_FLAG" = true ]; then
    local networkFlag='--network-flag'
  fi
  
  if [ ! "$SKIP_EXPORT" = true ]; then
    if [ ! "$PARALLEL_IMPORT" = true ]; then
      prepareForExport
    else
      prepareForExport_PI
    fi
  else
    echo "Skipped Export Process..."
  fi
}