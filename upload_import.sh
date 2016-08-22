#!/bin/bash

. parse_arguments.sh

# import instance based environment variables
. read_properties.sh $DEST

REMOTE_SCRIPT_DIR='mirror_db'
SITE_DIR="sites/${DIR}"
BACKUP_DIR='db_backup'
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
STRUCTURE_FILE='mirror_db_structure.sh'
PROPERTIES_FILE='db.properties'

chmod 774 $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE $STRUCTURE_FILE
chmod 774 $DROP_SQL_FILE.sql

cd ${BACKUP_DIR}

if [ -e $DB_FILE_NAME.sql ]; then
  echo "File ${DB_FILE_NAME}.sql found..."
  echo "Changing environment specific information"
  # Replace old domain with the new domain
  echo "Replacing Site URL..."
  echo "Running -> sed -i'' 's/'${SRC_URL}'/'${URL}'/g' ${DB_FILE_NAME}.sql"
  sed -i'' 's/'${SRC_URL}'/'${URL}'/g' ${DB_FILE_NAME}.sql

  # Replace Shib Production with Shib QA 
  echo "Replacing Shibboleth URL..."
  sed -i'' 's/'${SRC_SHIB_URL}'/'${SHIB_URL}'/g' ${DB_FILE_NAME}.sql
  
  echo "Replacing Google Analytics code..."
  sed -i'' 's/'${SRC_G_ANALYTICS}'/'${G_ANALYTICS}'/g' ${DB_FILE_NAME}.sql
fi

cd ..

expect <<- DONE
#establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}

#check connection and transfer file to pagely server
expect sftp>
send "put ${STRUCTURE_FILE}\r"
expect sftp>
send "bye\r"
expect eof 
DONE

ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} mk ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"

expect <<- DONE
#establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}/${REMOTE_SCRIPT_DIR}

#check connection and transfer file to pagely server

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
send "lcd ${BACKUP_DIR}\r"
expect sftp>
send "cd ${BACKUP_DIR}\r"
expect sftp>
send "put ${DB_FILE_NAME}.sql\r"
expect sftp>
send "bye\r"
expect eof 
DONE

if [[ $? == 0 ]]; then
  echo "File Transfer complete."

  echo "Starting to import database..."
  now=$(date +"%T")
  echo "Current time : $now "

  # Execute Import.sh to import database
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}/${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME};"

  # Check status of import script
  if [[ $? == 0 ]]; then
    echo "Database imported successfully..."
    now=$(date +"%T")
    echo "Current time : $now "
  else
    echo "Import Failed Check Log"
  fi

else
  echo "Transfer failed!"
  exit 1
fi

ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./${STRUCTURE_FILE} rm ${REMOTE_SCRIPT_DIR} ${BACKUP_DIR}"
