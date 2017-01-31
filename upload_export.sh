#!/bin/bash

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
	echo "Parsing arguments failed!"
	exit 1
fi

# Import instance based environment variables
. read_properties.sh $SRC
if [[ ! $? == 0 ]]; then
	echo "Read properties script failed!"
	exit 1
fi

EXPORT_DIR='db_export'
MERGED_DIR='db_merged'
EXPORT_SCRIPT='export.sh'
MERGE_SCRIPT='merge.sh'
GET_DB_SCRIPT='get_db.sh'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'

chmod 750 $EXPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE $MERGE_SCRIPT

if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
	echo "Creating ${REMOTE_SCRIPT_DIR} on ${SRC}..."
	ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};" 
fi

echo "Start Upload Export Process..."
now=$(date +"%T")
echo "Start time : $now "


# Establish sftp connection
sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR} << DONE
put ${STRUCTURE_FILE}
exit
DONE

echo "Executing structure script for creating dir on dest server... "
ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}" 

# Establish sftp connection
sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR} << DONE
put ${EXPORT_SCRIPT}
put ${MERGE_SCRIPT}
put ${PARSE_FILE}
put ${READ_PROPERTIES_FILE}
put ${PROPERTIES_FILE}
exit
DONE


# Executing export process at source
if [[ $? == 0 ]]; then
	if [ ! "$SKIP_EXPORT" = true ]; then
		ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${PARALLEL_IMPORT};" 
		if [[ ! $? == 0 ]]; then
			echo "Export script failed on ${SRC} server!"
			exit 1
		fi

		if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${DB_BACKUP_DIR} ]" ); then
			
			# Get path for source db relative to DB_BACKUP_DIR 
			DB_FILE_N=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}'`
			
			# Get absolute path for DB_BACKUP_DIR_PATH
			SRC_DB_BACKUP=`ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${DB_BACKUP_DIR}; cd ${DB_FILE_N}; pwd"`
		fi

		# Get exported db from SRC to mirror_db server
		echo "Transfering files from SRC to mirror_db server"
		./${GET_DB_SCRIPT} -s ${SRC} --db-backup ${SRC_DB_BACKUP} ${PARALLEL_IMPORT}
		
		if [[ ! $? == 0 ]]; then
			echo "Get DB script failed on mirror_db server!"
			exit 1
		fi

	else
		echo "Skipped Export Process..."
	fi
fi

# Check status of export command script
if [[ $? == 0 ]]; then

	# Removing MIRROR_DB from the source
	if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${REMOTE_SCRIPT_DIR} ]" ); then
		echo "Removing ${REMOTE_SCRIPT_DIR} from ${SRC}..."
		ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};" 
	fi

	echo "Upload Export completed..."
	now=$(date +"%T")
	echo "End time : $now "
else
	echo "Upload Export Failed Check Log"
	exit 1
fi