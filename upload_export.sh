#!/bin/bash

set -x

. utilityFunctions.sh
. export.sh

createRemoteScriptDir() {
  local location=$1
  if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
	echo "Creating ${REMOTE_SCRIPT_DIR} on ${location}..."
	ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};"
  fi
}

uploadMirrorDbFiles() {
  local location=$1
  rsync -avzhe ssh --delete --progress ${STRUCTURE_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
  echo "Executing structure script for creating dir on ${location} server... "
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
  rsync -avzhe ssh --delete --progress ${UTILITY_FILE} ${EXPORT_SCRIPT} ${MERGE_SCRIPT} ${PARSE_FILE} ${READ_PROPERTIES_FILE} ${PROPERTIES_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
}

removeMirrorDbFiles() {
  if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${REMOTE_SCRIPT_DIR} ]" ); then
    echo "Removing ${REMOTE_SCRIPT_DIR} from ${SRC}..."
	ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};"
  fi
}

#starts here
uploadExportMain() {
  parseArgs $@
  readProperties $SRC

  setFilePermissions
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
	  SRC_DB_BACKUP=$(ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}; cd ${DB_FILE_N}; pwd")
    fi

	# Get exported db from SRC to mirror_db server
	echo "Transferring files from SRC to mirror_db server"
	getDb -s ${SRC} --db-backup ${SRC_DB_BACKUP} ${PARALLEL_IMPORT}


    removeMirrorDbFiles
    echo "Upload Export completed..."
    now=$(date +"%T")
    echo "End time : $now "
  else
	echo "Skipped Export Process..."
  fi
}

