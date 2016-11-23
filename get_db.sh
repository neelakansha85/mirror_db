#!/bin/bash

BACKUP_DIR='db_backup'

. parse_arguments.sh

. read_properties.sh $SRC

if [ ! "$PARALLEL_IMPORT" = true ]; then
	rsync -avzhe ssh --include '*.sql' --exclude '*' --progress ${SSH_USERNAME}@${HOST_NAME}:${DB_PATH}/ ${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/ 
	#rsync -avzhe --progress ${DB_PATH}/ ~/${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/
else
	rsync -avzhe ssh --progress ${DB_PATH}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}
	
	# Remove that sql file to avoid imported twice
	rm ${BACKUP_DIR}/${MERGED_DIR}/${DB_FILE_NAME}
fi