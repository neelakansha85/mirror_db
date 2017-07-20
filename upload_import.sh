#!/bin/bash

. utilityFunctions.sh

prepareForImport() {
  local mirrorDbBackupDir=""
  uploadMirrorDbFiles $dest
  if [ ! -z $customDbBackupDir ]; then
    mirrorDbBackupDir=$customDbBackupDir
  elif [ ! -z $MIRROR_DB_BACKUP_DIR ]; then
    mirrorDbBackupDir=$MIRROR_DB_BACKUP_DIR
  else
    mirrorDbBackupDir=$DB_BACKUP_DIR
  fi
  echo "Uploading database files to $dest"
  putDb $mirrorDbBackupDir
  echo "File Transfer complete."
  echo "Starting to import database..."
  now=$(date +"%T")
  echo "Start time : $now "

  # Drop all tables using wp-cli before import process
  if [ "$dropTables" = true ]; then
    echo "Emptying Database using wp-cli..."
    # TODO: Use screen for waiting while dest performs db reset to avoid broken pipe
    ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${siteDir}; wp db reset --yes"
  fi
  # TODO: Use screen for waiting while dest performs import to avoid broken pipe
  # Execute Import.sh to import database
  ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${importScript} -s ${src} -d ${dest} -iwt ${importWaitTime} ${skipImport} ${forceImport} ${dropTableSql} ${skipReplace} ;"

  echo "Database imported successfully..."
  now=$(date +"%T")
  echo "End time : $now "
  removeMirrorDbFiles $dest
}

prepareForImport_PI() {
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    echo "Executing structure script for creating dir on dest server... "
    ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${structureFile} mk ${exportDir}"
  fi
  # Parallel Import for files that have been merged so far
  echo "Uploading ${DB_FILE_NAME}... "
  # Put all SQL files on ${dest} server from mirror_db server
  echo "Executing ${PUT_DB_SCRIPT} script"
  putDb ${DB_BACKUP_DIR}

  echo "Starting to import ${DB_FILE_NAME}..."
  now=$(date +"%T")
  echo "Start time : $now "

  # Execute search_replace.sh to replace old domains with new domain
  ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${SEARCH_REPLACE_SCRIPT} -s ${src} -d ${dest} ${skipReplace};"

  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    if [ ! "$skipNetworkImport" = true ]; then
      # Execute Import.sh to import network tables
      ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${importScript} -d ${dest} -dbf ${DB_FILE_NAME} -iwt ${importWaitTime} ${skipImport} ${forceImport} ${skipReplace};"
    else
      echo "Skipping importing Network Tables... "
    fi
  else
    # Execute Import.sh to import all non-network tables
    ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${importScript} -d ${dest} -dbf ${DB_FILE_NAME} -iwt ${importWaitTime} ${skipImport} ${forceImport};"
  fi

  echo "${DB_FILE_NAME} imported successfully..."
  now=$(date +"%T")
  echo "End time : $now "

  if [ "$isLastImport" = true ]; then
    echo "Changing permission for structure file before cleanup... "
    ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; chmod 755 ${structureFile}"
    removeMirrorDbFiles $dest
  fi
}

uploadImportMain(){
  local isLastImport=false
  readProperties $dest

  createRemoteScriptDir $dest

  if [ ! "$parallelImport" = true ]; then
    prepareForImport
  else
    prepareForImport_PI
  fi
}
