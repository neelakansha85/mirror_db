#!/bin/bash

# default values
IS_LAST_IMPORT=false

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
    echo "Parsing arguments failed!"
    exit 1
fi

# Import instance based environment variables
. read_properties.sh $DEST
if [[ ! $? == 0 ]]; then
    echo "Read properties script failed!"
    exit 1
fi

EXPORT_DIR='db_export'
MERGED_DIR='db_merged'
IMPORT_SCRIPT='import.sh'
SEARCH_REPLACE_SCRIPT='search_replace.sh'
GET_DB_SCRIPT='get_db.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'
PI_TOTAL_FILE='pi_total.txt'
SRC_DB_BACKUP="${DB_BACKUP}"

if [ "$REMOTE_SCRIPT_DIR" = '' ]; then
	REMOTE_SCRIPT_DIR='mirror_db'
fi

if [ "$SKIP_IMPORT" = true ]; then
  SKIP_IMPORT='--skip-import'
fi

if [ "$DROP_TABLES_SQL" = true ]; then
  DROP_TABLES_SQL='--drop-tables-sql'
fi

chmod 750 $IMPORT_SCRIPT $SEARCH_REPLACE_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE $GET_DB_SCRIPT
chmod 754 $DROP_SQL_FILE.sql

# Create REMOTE_SCRIPT_DIR on server
if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
  echo "Creating ${REMOTE_SCRIPT_DIR} on ${DEST}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};" 
fi

# Establish sftp connection
sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR} << DONE
put ${STRUCTURE_FILE}
exit
DONE

if [ "$PARALLEL_IMPORT" = true ]; then
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    echo "Executing structure script for creating dir on dest server... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
  fi
else
    echo "Executing structure script for creating dir on dest server... "
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
fi

# Establish sftp connection
sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR} << DONE
put ${IMPORT_SCRIPT}
put ${SEARCH_REPLACE_SCRIPT}
put ${PARSE_FILE}
put ${READ_PROPERTIES_FILE}
put ${PROPERTIES_FILE}
put ${DROP_SQL_FILE}.sql
put ${GET_DB_SCRIPT}
#lcd ${EXPORT_DIR}
#cd ${EXPORT_DIR}
#mput *.sql
exit
DONE

if [ ! "$PARALLEL_IMPORT" = true ]; then
  # This rsync will be inside get_db.sh
  # Execute get_db.sh on dest server from here
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${GET_DB_SCRIPT} -s ${SRC} --db-backup ${SRC_DB_BACKUP} ${PARALLEL_IMPORT}"
  if [[ ! $? == 0 ]]; then
    echo "Get DB script failed on ${DEST} server!"
    exit 1
  fi

  # Upload all *.sql files using rsync
  #rsync -avzhe ssh --include '*.sql' --exclude '*' --progress ${EXPORT_DIR}/${MERGED_DIR}/ ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/

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

    # Execute search_replace.sh to replace old domains with new domain
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${SEARCH_REPLACE_SCRIPT} -s ${SRC} -d ${DEST} ${SKIP_REPLACE};"
    if [[ ! $? == 0 ]]; then
      echo "Search replace script failed on ${DEST} server!"
      exit 1
    fi

    # Execute Import.sh to import database
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${DROP_TABLES_SQL} ;"
    if [[ ! $? == 0 ]]; then
      echo "Import script failed on ${DEST} server!"
      exit 1
    fi

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
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} rm ${EXPORT_DIR}"

  # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm ${STRUCTURE_FILE}"

else
  # Parallel Import for files that have been merged so far
  
  echo "Uploading ${DB_FILE_NAME}... "
  
  # This rsync will be inside get_db.sh
  # Execute get_db.sh on dest server from here
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${GET_DB_SCRIPT} -s ${SRC} -dbf ${DB_FILE_NAME}  --db-backup ${SRC_DB_BACKUP} ${PARALLEL_IMPORT}"
  if [[ ! $? == 0 ]]; then
    echo "Get DB script failed on ${DEST} server!"
    exit 1
  fi

  # Upload one sql at a time using rsync
  #rsync -avzhe ssh --progress ${EXPORT_DIR}/${MERGED_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/
  
  # Remove that sql file to avoid imported twice
  # rm ${EXPORT_DIR}/${MERGED_DIR}/${DB_FILE_NAME}

  echo "Starting to import ${DB_FILE_NAME}..."
  now=$(date +"%T")
  echo "Start time : $now "
  
  # Execute search_replace.sh to replace old domains with new domain
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${SEARCH_REPLACE_SCRIPT} -s ${SRC} -d ${DEST} ${SKIP_REPLACE};"
  if [[ ! $? == 0 ]]; then
    echo "Search replace script failed on ${DEST} server!"
    exit 1
  fi

  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    if [ ! "$SKIP_NETWORK_IMPORT" = true ]; then
    # Execute Import.sh to import network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${SKIP_REPLACE};"
      if [[ ! $? == 0 ]]; then
        echo "Import script failed on ${DEST} server for network tables!"
        exit 1
      fi
    else
      echo "Skipping importing Network Tables... "
    fi
  else
    # Execute Import.sh to import all non-network tables
      ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT};"
      if [[ ! $? == 0 ]]; then
        echo "Import script failed on ${DEST} server for all site tables!"
        exit 1
      fi
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
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} rm ${EXPORT_DIR}"

    # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm ${STRUCTURE_FILE}"
  fi
fi

