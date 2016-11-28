#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'

. parse_arguments.sh

. read_properties.sh $SRC

SRC_URL=",'${URL}"
SRC_URL2=",'http://${URL}"
SRC_URL3=",'https://${URL}"
SRC_SHIB_URL=",'${SHIB_URL}'"
SRC_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"
SRC_G_ANALYTICS="${G_ANALYTICS}"

. read_properties.sh $DEST

DEST_URL=",'${URL}"
DEST_URL2=",'http://${URL}"
DEST_URL3=",'https://${URL}"
DEST_SHIB_URL=",'${SHIB_URL}'"
DEST_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"
DEST_G_ANALYTICS="${G_ANALYTICS}"

#Replacing Values from old domain to new domain
cd ${BACKUP_DIR}

if [ ! "$SKIP_REPLACE" = true ]; then
  for MRDB in `ls *.sql`
  do
    if [ -e ${MRDB} ]; then
      echo "File ${MRDB} found..."
      echo "Changing environment specific information"
      if [ ! -z ${SRC_SHIB_URL} ] && [ "${SRC_SHIB_URL}" != "''" ]; then
        # Replace Shib Production with Shib QA 
        echo "Replacing Shibboleth URL..."
        sed -i'' "s@${SRC_SHIB_URL}@${DEST_SHIB_URL}@g" ${MRDB}
        sed -i'' "s@${SRC_SHIB_LOGOUT_URL}@${DEST_SHIB_LOGOUT_URL}@g" ${MRDB}
      fi

      if [ ! -z ${SRC_URL} ]; then
        # Replace old domain with the new domain
        echo "Replacing Site URL..."
        echo "Running -> sed -i'' \"s@${SRC_URL}@${DEST_URL}@g\" ${MRDB}"
        sed -i'' "s@${SRC_URL}@${DEST_URL}@g" ${MRDB}

        echo "Running -> sed -i'' \"s@${SRC_URL2}@${DEST_URL2}@g\" ${MRDB}"
        sed -i'' "s@${SRC_URL2}@${DEST_URL2}@g" ${MRDB}

        echo "Running -> sed -i'' \"s@${SRC_URL3}@${DEST_URL3}@g\" ${MRDB}"
        sed -i'' "s@${SRC_URL3}@${DEST_URL3}@g" ${MRDB}
        
      fi

      if [ ! -z ${SRC_G_ANALYTICS} ] && [ "${SRC_G_ANALYTICS}" != "''" ]; then
        echo "Replacing Google Analytics code..."
        sed -i'' "s@${SRC_G_ANALYTICS}@${DEST_G_ANALYTICS}@g" ${MRDB}
      fi
    fi
  done
fi

# Get to root dir
cd ..
