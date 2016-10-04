#!/bin/bash

# default values
IS_LAST_IMPORT=false

. parse_arguments.sh

# Import instance based environment variables
. read_properties.sh $DEST

BACKUP_DIR='db_backup'
MERGED_DIR='db_merged'
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'
PI_TOTAL_FILE='pi_total.txt'

if [ "$REMOTE_SCRIPT_DIR" = '' ]; then
	REMOTE_SCRIPT_DIR='mirror_db'
fi

if [ "$SKIP_IMPORT" = true ]; then
  SKIP_IMPORT='--skip-import'
fi

if [ "$DROP_TABLES_SQL" = true ]; then
  DROP_TABLES_SQL='--drop-tables-sql'
fi

chmod 750 $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE
chmod 754 $DROP_SQL_FILE.sql

cd ${BACKUP_DIR}/${MERGED_DIR}

if [ ! "$SKIP_REPLACE" = true ]; then
  for MRDB in `ls *.sql`
  do
    if [ -e ${MRDB} ]; then
      echo "File ${MRDB} found..."
      echo "Changing environment specific information"
      if [ ! -z ${SRC_URL} ]; then
        # Replace old domain with the new domain
        echo "Replacing Site URL..."
        echo "Running -> sed -i'' 's/'${SRC_URL}'/'${URL}'/g' ${MRDB}"
        sed -i '' 's/'${SRC_URL}'/'${URL}'/g' ${MRDB}
      fi

      if [ ! -z ${SRC_SHIB_URL} ] && [ "${SRC_SHIB_URL}" != "''" ]; then
        # Replace Shib Production with Shib QA 
        echo "Replacing Shibboleth URL..."
        sed -i '' 's/'${SRC_SHIB_URL}'/'${SHIB_URL}'/g' ${MRDB}
      fi

      if [ ! -z ${SRC_G_ANALYTICS} ] && [ "${SRC_G_ANALYTICS}" != "''" ]; then
        echo "Replacing Google Analytics code..."
        sed -i '' 's/'${SRC_G_ANALYTICS}'/'${G_ANALYTICS}'/g' ${MRDB}
      fi
    fi
  done
fi

# Get to root dir
cd ../..

# Create REMOTE_SCRIPT_DIR on server
if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
  echo "Creating ${REMOTE_SCRIPT_DIR} on ${DEST}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};" 
fi

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}

# Check connection and transfer file to destination server
expect sftp>
send "put ${STRUCTURE_FILE}\r"
expect sftp>
send "exit\r"
expect eof 
DONE

if [ "$PARALLEL_IMPORT" = true ]; then
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    echo "Executing structure script for creating dir on dest server... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${BACKUP_DIR}"
  fi
else
    echo "Executing structure script for creating dir on dest server... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${BACKUP_DIR}"
fi

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}

# Check connection and transfer all files to destination server

expect sftp>
send "put ${IMPORT_SCRIPT}\r"
expect sftp>
send "put ${PARSE_FILE}\r"
expect sftp>
send "put ${READ_PROPERTIES_FILE}\r"
expect sftp>
send "put ${PROPERTIES_FILE}\r"
expect sftp>
send "put ${DROP_SQL_FILE}.sql\r"
expect sftp>
#send "lcd ${BACKUP_DIR}\r"
#expect sftp>
#send "cd ${BACKUP_DIR}\r"
#expect sftp>
#send "mput *.sql\r"
#expect sftp>
send "exit\r"
expect eof 
DONE

if [ ! "$PARALLEL_IMPORT" = true ]; then
  # Upload all *.sql files using rsync
  rsync -avzhe ssh --include '*.sql' --exclude '*' --progress ${BACKUP_DIR}/${MERGED_DIR}/ ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/

  if [[ $? == 0 ]]; then
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
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${DROP_TABLES_SQL};"

    # Check status of import script
    if [[ $? == 0 ]]; then
      echo "Database imported successfully..."
      now=$(date +"%T")
      echo "End time : $now "
    else
      echo "Import Failed Check Log"
    fi

  else
    echo "Transfer failed!"
    exit 1
  fi

  # Remove all scripts related to mirror_db from server
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} rm ${BACKUP_DIR}"

  # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm ${STRUCTURE_FILE}"

else
  # Parallel Import for files that have been merged so far
  
  echo "Uploading ${DB_FILE_NAME}... "
  # Upload one sql at a time using rsync
  rsync -avzhe ssh --progress ${BACKUP_DIR}/${MERGED_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/
  
  # Remove that sql file to avoid imported twice
  rm ${BACKUP_DIR}/${MERGED_DIR}/${DB_FILE_NAME}

  echo "Starting to import ${DB_FILE_NAME}..."
  now=$(date +"%T")
  echo "Start time : $now "
  
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    if [ ! "$SKIP_NETWORK_IMPORT" = true ]; then
      # Execute Import.sh to import network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT};"
    else
      echo "Skipping importing Network Tables... "
    fi
  else
    # Execute Import.sh to import all non-network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT};"
  fi

  # Check status of import script
  if [[ $? == 0 ]]; then
    echo "${DB_FILE_NAME} imported successfully..."
    now=$(date +"%T")
    echo "End time : $now "
  else
    echo "Import Failed for ${DB_FILE_NAME}"
    exit 1
  fi
  
  # Remove all files if this is the last import 
  if [ "$IS_LAST_IMPORT" = true ]; then
    echo "Changing permission for structure file before cleanup... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; chmod 755 ${STRUCTURE_FILE}"

    # Remove all scripts related to mirror_db from server
    echo "Removing all mirror_db scripts from dest... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} rm ${BACKUP_DIR}"

    # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm ${STRUCTURE_FILE}"
  fi
fi

