#!/bin/bash

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
	echo "FAILURE: Error parsing arguments!"
	exit 1
fi

# Import instance based environment variables
. read_properties.sh $SRC
if [[ ! $? == 0 ]]; then
	echo "FAILURE: Error reading properties!"
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
UTILITY_FILE='utilityFunctions.sh'

chmod 750 $UTILITY_FILE $EXPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE $MERGE_SCRIPT

if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
	echo "Creating ${REMOTE_SCRIPT_DIR} on ${SRC}..."
	ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};" 
fi
echo $BLOG_ID
echo "Start Upload Export Process..."
now=$(date +"%T")
echo "Start time : $now "


# Establish sftp connection
rsync -avzhe ssh --delete --progress ${STRUCTURE_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/

echo "Executing structure script for creating dir on ${SRC} server... "
ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}" 

# Send export process related files to SOURCE
rsync -avzhe ssh --delete --progress ${UTILITY_FILE} ${EXPORT_SCRIPT} ${MERGE_SCRIPT} ${PARSE_FILE} ${READ_PROPERTIES_FILE} ${PROPERTIES_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/

if [[ ! $? == 0 ]]; then
	echo "FAILURE: Error uploading mirror_db files on ${SRC} server!"
	exit 1
else
# Executing export process at source
	if [ ! "$SKIP_EXPORT" = true ]; then
		ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} -blogid ${BLOG_ID} ${PARALLEL_IMPORT} ${NETWORK_FLAG};" 
		if [[ ! $? == 0 ]]; then
			echo "FAILURE: Error executing export script on ${SRC} server!"
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
			echo "FAILURE: Error executing Get DB script on mirror_db server!"
			exit 1
		fi

	else
		echo "Skipped Export Process..."
	fi	
fi

# Check status of export command script
if [[ ! $? == 0 ]]; then
	echo "FAILURE: Error exporting database on ${SRC}!"
	exit 1
else
	# Removing MIRROR_DB from the source
	if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${REMOTE_SCRIPT_DIR} ]" ); then
		echo "Removing ${REMOTE_SCRIPT_DIR} from ${SRC}..."
		ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};" 
	fi

	echo "Upload Export completed..."
	now=$(date +"%T")
	echo "End time : $now "
fi