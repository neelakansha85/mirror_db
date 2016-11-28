#!/bin/bash

EXPORT_DIR='db_export'

. parse_arguments.sh

. read_properties.sh $SRC

if [ ! "$PARALLEL_IMPORT" = true ]; then
	rsync -avzhe ssh --include '*.sql' --exclude '*' --progress ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/ 
else
	rsync -avzhe ssh --progress ${DB_BACKUP_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/
	
fi