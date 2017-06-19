#!/bin/bash

EXPORT_DIR='db_export'

. utilityFunctions.sh

getDb() {
  parseArgs $@
  readProperties $SRC

  if [ ! -z $DB_BACKUP ]; then
	DB_BACKUP_DIR=${DB_BACKUP}
  fi

  if [ ! "$PARALLEL_IMPORT" = true ]; then
	rsync -avzhe ssh --include '*.sql' --exclude '*' --delete --progress ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/
  else
	rsync -avzhe ssh --progress ${DB_BACKUP_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/
  fi
  #is the space btw backup_dir and export_dir needed
  DB_BACKUP=${EXPORT_DIR}
}

getDb $@