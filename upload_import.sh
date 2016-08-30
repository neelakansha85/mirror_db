#!/bin/bash

. parse_arguments.sh

# Import instance based environment variables
. read_properties.sh $DEST

REMOTE_SCRIPT_DIR='mirror_db'
BACKUP_DIR='db_backup'
MERGED_DIR='db_merged'
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'
PI_TOTAL_FILE='pi_total.txt'

if [ "$SKIP_IMPORT" = true ]; then
  SKIP_IMPORT='--skip-import'
fi

if [ "$DROP_TABLES_SQL" = true ]; then
  DROP_TABLES='--drop-tables-sql'
fi

chmod 774 $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE
chmod 774 $DROP_SQL_FILE.sql

cd ${BACKUP_DIR}/${MERGED_DIR}


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

cd ../..

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}

# Check connection and transfer file to destination server
expect sftp>
send "put ${STRUCTURE_FILE}\r"
expect sftp>
send "exit\r"
expect eof 
DONE

if [ "$PARALLEL_IMPORT" = true ]; then
  if [[ $DB_FILE_NAME =~ .*_network.* ]]; then
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} mk ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"
  fi
else
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} mk ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"
fi

expect <<- DONE
# Establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}/${REMOTE_SCRIPT_DIR}

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
  rsync -avzhe ssh --include '*.sql' --exclude '*' --progress ${BACKUP_DIR}/${MERGED_DIR} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}/${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/

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
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}/${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT} ${DROP_TABLES_SQL};"

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
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} rm ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"

  # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; rm ${STRUCTURE_FILE}"

else
  # Parallel Import for files that have been merged so far
  if [ -e $PI_TOTAL_FILE ]; then
    . $PI_TOTAL_FILE
  fi

  IS_LAST_IMPORT=false
  
  # Upload one *.sql at a time using rsync
  rsync -avzhe ssh --include '${DB_FILE_NAME}' --exclude '*' --progress ${BACKUP_DIR}/${MERGED_DIR} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}/${REMOTE_SCRIPT_DIR}/${BACKUP_DIR}/
  
  # Remove that sql file to avoid imported twice
  rm ${DB_FILE_NAME}

  echo "Starting to import ${DB_FILE_NAME}..."
  now=$(date +"%T")
  echo "Start time : $now "
  
  # Execute Import.sh to import database
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}/${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -iwt ${IMPORT_WAIT_TIME} ${SKIP_IMPORT} ${FORCE_IMPORT};"

  # Check status of import script
  if [[ $? == 0 ]]; then
    echo "${DB_FILE_NAME} imported successfully..."
    now=$(date +"%T")
    echo "End time : $now "
    SQL_TOTAL=`echo ${DB_FILE_NAME} | sed 's/\./ /g' | awk '{print $1}' | rev | cut -d'_' -f1 | rev`
    if [ $SQL_TOTAL == $PI_TOTAL ]; then
      IS_LAST_IMPORT=true
    fi
  else
    echo "Import Failed for ${DB_FILE_NAME}"
    exit 1
  fi
  
  # Remove all files if this is the last import 
  if [ $IS_LAST_IMPORT ]; then
    # Remove all scripts related to mirror_db from server
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} rm ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"

    # Remove ${STRUCTURE_FILE} from server to avoid permission issues later
    ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; rm ${STRUCTURE_FILE}"
  fi
fi

