#!/bin/bash

. utilityFunctions.sh

prepareForImport() {
  # Get correct location of DB files for putDb()
  local mirrorDbBackupDir=""
  uploadMirrorDbFiles $DEST
  if [ ! -z $CUSTOM_DB_BACKUP_DIR ]; then
    mirrorDbBackupDir=$CUSTOM_DB_BACKUP_DIR
  elif [ ! -z $MIRROR_DB_BACKUP_DIR ]; then
    mirrorDbBackupDir=$MIRROR_DB_BACKUP_DIR
  else
    mirrorDbBackupDir=$DB_BACKUP_DIR
  fi

  echo "Uploading database files to $DEST"
  putDb $mirrorDbBackupDir
  echo "File Transfer complete."
  now=$(date +"%T")
  echo "Start time : $now "

  # Drop all tables using wp-cli before import process
  if [ "$DROP_TABLES" = true ]; then
    echo "Emptying Database using wp-cli..."
    # TODO: Use screen for waiting while DEST performs db reset to avoid broken pipe
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; wp db reset --yes"
  fi
  # TODO: Use screen for waiting while DEST performs import to avoid broken pipe
  # Execute Import.sh to import database
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -s ${SRC} -d ${DEST} -iwt ${IMPORT_WAIT_TIME} ${FORCE_IMPORT} ${skipImport} ${dropTableSql} ${skipReplace} ;"

  now=$(date +"%T")
  echo "End time : $now "
  removeMirrorDbFiles $DEST
}

prepareForImport_PI() {
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    echo "Executing structure script for creating dir on DEST server... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
  fi
  # Parallel Import for files that have been merged so far
  echo "Uploading ${DB_FILE_NAME}... "
  # Put all SQL files on ${DEST} server from mirror_db server
  echo "Executing ${PUT_DB_SCRIPT} script"
  putDb ${DB_BACKUP_DIR}

  echo "Starting to import ${DB_FILE_NAME}..."
  now=$(date +"%T")
  echo "Start time : $now "

  # Execute search_replace.sh to replace old domains with new domain
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${SEARCH_REPLACE_SCRIPT} -s ${SRC} -d ${DEST} ${skipReplace};"

  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    if [ ! "$SKIP_NETWORK_IMPORT" = true ]; then
      # Execute Import.sh to import network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${FORCE_IMPORT} ${skipImport} ${skipReplace} ${skipNetworkImport};"
    else
      echo "Skipping importing Network Tables... "
    fi
  else
    # Execute Import.sh to import all non-network tables
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${FORCE_IMPORT} ${skipImport} ;"
  fi

  echo "${DB_FILE_NAME} imported successfully..."
  now=$(date +"%T")
  echo "End time : $now "

  if [ "$isLastImport" = true ]; then
    echo "Changing permission for structure file before cleanup... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; chmod 755 ${STRUCTURE_FILE}"
    removeMirrorDbFiles $DEST
  fi
}

uploadImportMain(){
  local isLastImport=false
  # Check all flags for passing correct values to import script
  if [ "$SKIP_IMPORT" = true ]; then
    local skipImport="--skip-import"
  fi
  if [ "$SKIP_REPLACE" = true ]; then
    local skipReplace="--skip-replace"
  fi
  if [ "$SKIP_NETWORK_IMPORT" = true ]; then
    local skipNetworkImport="--skip-network-import"
  fi
  if [ "$DROP_TABLE_SQL" = true ]; then
    local dropTableSql="--drop-tables-sql"
  fi

  readProperties $DEST

  createRemoteScriptDir $DEST

  if [ ! "$PARALLEL_IMPORT" = true ]; then
    prepareForImport
  else
    prepareForImport_PI
  fi
}
