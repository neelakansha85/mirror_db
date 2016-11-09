#!/bin/bash

BATCH_LIMIT=10
POOL_LIMIT=7000
MERGE_BATCH_LIMIT=7000
WAIT_TIME=3
IMPORT_WAIT_TIME=180
LIST_FILE_NAME='table_list.txt'
DB_FILE_NAME="mysql_$(date +"%Y-%m-%d").sql"

. parse_arguments.sh

echo "PARAMETERS"
# Import instance based environment variables
. read_properties.sh $SRC

echo "PARAMETERS"
ARCHIVES_DIR='db_archives'
BACKUP_DIR='db_backup'
MERGED_DIR='db_merged'
EXPORT_SCRIPT='export.sh'
MERGE_SCRIPT='merge.sh'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'

chmod 750 $EXPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE $MERGE_SCRIPT

if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
  echo "Creating ${REMOTE_SCRIPT_DIR} on ${SRC}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};" 
fi

echo "Starting to export..."
now=$(date +"%T")
echo "Start time : $now "

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}

# Check connection and transfer file to source server
expect sftp>
send "put ${STRUCTURE_FILE}\r"
expect sftp>
send "exit\r"
expect eof 
DONE

echo "Executing structure script for creating dir on dest server... "
ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${BACKUP_DIR}" 

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}

# Check connection and transfer all files to source server
expect sftp>
send "put ${EXPORT_SCRIPT}\r"
expect sftp>
send "put ${MERGE_SCRIPT}\r"
expect sftp>
send "put ${PARSE_FILE}\r"
expect sftp>
send "put ${READ_PROPERTIES_FILE}\r"
expect sftp>
send "put ${PROPERTIES_FILE}\r"
expect sftp>
send "exit\r"
expect eof 
DONE

# Executing export prcoess at source
if [[ $? == 0 ]]; then
	ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${EXPORT_SCRIPT} -s ${SRC} -d ${DEST} -ebl ${BATCH_LIMIT} -pl ${POOL_LIMIT} -mbl ${MERGE_BATCH_LIMIT} -ewt ${WAIT_TIME} -lf ${LIST_FILE_NAME} -dbf ${DB_FILE_NAME} ${PARALLEL_IMPORT};" 
fi

# Check status of export command script
if [[ $? == 0 ]]; then
	if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${ARCHIVES_DIR} ]" ); then
		echo "Getting current directory for ${ARCHIVES_DIR} on ${SRC}..."
		
		#fetching current home directory for Archive Dir
		ARCHIVES_WORK_DIR=`ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "pwd"`

		#getting specific SQL folder from Archives Dir
		DB_FILE_N=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}'`
		
		# Setting value for parent variable ARCHIVES_DIR_PATH
		ARCHIVES_DIR_PATH="${ARCHIVES_WORK_DIR}/${ARCHIVES_DIR}/${DB_FILE_N}"
	fi

	#Removing MIRROR_DB from the source
	if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${REMOTE_SCRIPT_DIR} ]" ); then
	   echo "Creating ${REMOTE_SCRIPT_DIR} on ${SRC}..."
	   ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};" 
	fi

	echo "Database exported successfully..."
	now=$(date +"%T")
	echo "End time : $now "
else
  echo "Export Failed Check Log"
fi