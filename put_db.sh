#!/bin/bash

EXPORT_DIR='db_export'

. utilityFunctions.sh

putDb() {
  parseArgs $@
  readProperties $DEST

#  if [ "$DB_BACKUP" != "''" ]; then
#	#DB_BACKUP_DIR=${DB_BACKUP}
#  else
#    DB_BACKUP_DIR=${EXPORT_DIR}
#  fi

  if [ ! "$PARALLEL_IMPORT" = true ]; then
    echo "Database path on mirror_db: $DB_BACKUP_DIR"
	rsync -avzhe ssh --include '*.sql' --exclude '*'  --delete --progress ${DB_BACKUP_DIR}/ ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/
  else
	rsync -avzhe ssh --progress ${EXPORT_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/
  fi

  echo "DB dir on Dest server: "
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/; pwd;"

}
putDb $@
