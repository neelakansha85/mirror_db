#!/bin/bash

# Config Options

EXPORT_DIR='db_export'

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
    echo "Parse arguments script failed!"
    exit 1
fi

. read_properties.sh $SRC
if [[ ! $? == 0 ]]; then
    echo "Read properties script failed!"
    exit 1
fi

SRC_URL=",'${URL}"
SRC_URL2=",'http://${URL}"
SRC_URL3=",'https://${URL}"
SRC_SHIB_URL=",'${SHIB_URL}'"
SRC_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"
SRC_G_ANALYTICS="${G_ANALYTICS}"
SRC_CDN_URL="${CDN_URL}"
SRC_HTTPS_CDN_URL="${HTTPS_CDN_URL}"

. read_properties.sh $DEST
if [[ ! $? == 0 ]]; then
    echo "Read properties script failed!"
    exit 1
fi

DEST_URL=",'${URL}"
DEST_URL2=",'http://${URL}"
DEST_URL3=",'https://${URL}"
DEST_SHIB_URL=",'${SHIB_URL}'"
DEST_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"
DEST_G_ANALYTICS="${G_ANALYTICS}"
DEST_CDN_URL="${CDN_URL}"
DEST_HTTPS_CDN_URL="${HTTPS_CDN_URL}"

#Replacing Values from old domain to new domain
cd ${EXPORT_DIR}

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

      if [ ! -z ${SRC_CDN_URL} ] && [ "${SRC_CDN_URL}" != "''" ] && [ ! -z ${SRC_HTTPS_CDN_URL} ] && [ "${SRC_HTTPS_CDN_URL}" != "''" ] ; then
        echo "Replacing CDN URL..."
        sed -i'' "s@${SRC_CDN_URL}@${DEST_CDN_URL}@g" ${MRDB}
        sed -i'' "s@${SRC_HTTPS_CDN_URL}@${DEST_HTTPS_CDN_URL}@g" ${MRDB}
      fi
    fi
  done
fi

# Get to root dir
cd ..
