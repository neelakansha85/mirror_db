#!/bin/bash

. parse_arguments.sh

# import instance based environment variables
. read_properties.sh $DEST

REMOTE_SCRIPT_DIR='mirror_db'
SITE_DIR="sites/${DIR}"
ARCHIVES_DIR='archives'
IMPORT_SCRIPT='import.sh'
DROP_SQL_FILE='drop_tables'
PARSE_FILE='parse_arguments.sh'
READ_PROPERTIES_FILE='read_properties.sh'
PROPERTIES_FILE='db.properties'

chmod 774 $IMPORT_SCRIPT $PARSE_FILE $READ_PROPERTIES_FILE $PROPERTIES_FILE structure.sh
chmod 774 $ARCHIVES_DIR/$DROP_SQL_FILE.sql


expect <<- DONE
#establish sftp connection
spawn sftp -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME}:${SITE_DIR}

#check connection and transfer file to pagely server
expect sftp>
send "put structure.sh\r"
expect sftp>
send "bye\r"
expect eof 
DONE

ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./structure.sh mk ${REMOTE_SCRIPT_DIR} ${ARCHIVES_DIR}"

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
send "lcd ${ARCHIVES_DIR}\r"
expect sftp>
send "cd ${ARCHIVES_DIR}\r"
expect sftp>
send "put ${DB_FILE_NAME}.sql\r"
expect sftp>
send "bye\r"
expect eof 
DONE

if [[ $? == 0 ]]; then
  echo "File Transfer complete."

  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}/${REMOTE_SCRIPT_DIR}; ./${IMPORT_SCRIPT} -d ${DEST} -dbf ${DB_FILE_NAME} -site-url ${SRC_URL} -shib ${SRC_SHIB_URL} -g-analytics ${SRC_G_ANALYTICS};"

  #check status of import script
  if [[ $? == 0 ]]; then
    echo "Closing import script..."
  else
    echo "Import Failed Check Log"
  fi

else
  echo "Transfer failed!"
  exit 1
fi

ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${SITE_DIR}; ./structure.sh rm ${REMOTE_SCRIPT_DIR} ${ARCHIVES_DIR}"
