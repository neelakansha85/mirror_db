#!/bin/bash

. utilityFunctions.sh

uploadImportMain(){
  local isLastImport=false
  readProperties $DEST

  if [ "$REMOTE_SCRIPT_DIR" = '' ]; then
	  REMOTE_SCRIPT_DIR='mirror_db'
  fi

  if [ "$SKIP_IMPORT" = true ]; then
    SKIP_IMPORT='--skip-import'
  fi

  if [ "$DROP_TABLES_SQL" = true ]; then
    DROP_TABLES_SQL='--drop-tables-sql'
  fi

  createRemoteScriptDir $DEST

  if [ ! "$PARALLEL_IMPORT" = true ]; then
    uploadMirrorDbFiles $DEST

    if [[ "$DB_BACKUP" == "''" ]]; then
      DB_BACKUP=${EXPORT_DIR}      
    fi
    echo "Executing ${PUT_DB_SCRIPT} script"
    putDb ${DB_BACKUP}
    echo "File Transfer complete."

    echo "Starting to import database..."
    now=$(date +"%T")
    echo "Start time : $now "

    # Drop all tables using wp-cli before import process
    if [ "$DROP_TABLES" = true ]; then
      echo "Emptying Database using wp-cli..."
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; wp db reset --yes"
    fi

    # Execute Import.sh to import database
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${DROP_TABLES_SQL} ;"

    echo "Database imported successfully..."
    now=$(date +"%T")
    echo "End time : $now "
    removeMirrorDbFiles $DEST

  else

    if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
      echo "Executing structure script for creating dir on dest server... "
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
    fi
    # Parallel Import for files that have been merged so far
    echo "Uploading ${DB_FILE_NAME}... "
    # Put all SQL files on ${DEST} server from mirror_db server
    echo "Executing ${PUT_DB_SCRIPT} script"
    putDb ${DB_BACKUP}

    echo "Starting to import ${DB_FILE_NAME}..."
    now=$(date +"%T")
    echo "Start time : $now "

    # Execute search_replace.sh to replace old domains with new domain
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${SEARCH_REPLACE_SCRIPT} -s ${SRC} -d ${DEST} ${SKIP_REPLACE};"

    if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
      if [ ! "$SKIP_NETWORK_IMPORT" = true ]; then
        # Execute Import.sh to import network tables
        ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${SKIP_REPLACE};"
      else
        echo "Skipping importing Network Tables... "
      fi
    else
      # Execute Import.sh to import all non-network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT};"
    fi

    echo "${DB_FILE_NAME} imported successfully..."
    now=$(date +"%T")
    echo "End time : $now "

    if [ "$isLastImport" = true ]; then
      echo "Changing permission for structure file before cleanup... "
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; chmod 755 ${STRUCTURE_FILE}"

      removeMirrorDbFiles $DEST
    fi
  fi
}
