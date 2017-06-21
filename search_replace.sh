#!/bin/bash

# Config Options
. utilityFunctions.sh

changeEnvInfo() {
  local MRDB=$1
  local SRC_SHIB_URL=$2
  local DEST_SHIB_URL=$3
  local SRC_SHIB_LOGOUT_URL=$4
  local DEST_SHIB_LOGOUT_URL=$5
  echo "File ${MRDB} found..."
  echo "Changing environment specific information"
  if [ ! -z ${SRC_SHIB_URL} ] && [ "${SRC_SHIB_URL}" != "''" ]; then
    # Replace Shib Production with Shib QA
    echo "Replacing Shibboleth URL..."
    sed -i'' "s@${SRC_SHIB_URL}@${DEST_SHIB_URL}@g" ${MRDB}
    sed -i'' "s@${SRC_SHIB_LOGOUT_URL}@${DEST_SHIB_LOGOUT_URL}@g" ${MRDB}
  fi
}

replaceDomain() {
  local MRDB=$1
  local SRC_URL=$2
  local SRC_URL2=$3
  local SRC_URL3=$4

  local DEST_URL=$5
  local DEST_URL2=$6
  local DEST_URL3=$7
  # Replace old domain with the new domain
  echo "Replacing Site URL..."
  echo "Running -> sed -i'' \"s@${SRC_URL}@${DEST_URL}@g\" ${MRDB}"
  sed -i'' "s@${SRC_URL}@${DEST_URL}@g" ${MRDB}

  echo "Running -> sed -i'' \"s@${SRC_URL2}@${DEST_URL2}@g\" ${MRDB}"
  sed -i'' "s@${SRC_URL2}@${DEST_URL2}@g" ${MRDB}

  echo "Running -> sed -i'' \"s@${SRC_URL3}@${DEST_URL3}@g\" ${MRDB}"
  sed -i'' "s@${SRC_URL3}@${DEST_URL3}@g" ${MRDB}
}

replaceCDNUrl() {
  local MRDB=$1
  local SRC_CDN_URL=$2
  local DEST_CDN_URL=$3
  local SRC_HTTPS_CDN_URL=$4
  local DEST_HTTPS_CDN_URL=$5
  echo "Replacing CDN URL..."
  sed -i'' "s@${SRC_CDN_URL}@${DEST_CDN_URL}@g" ${MRDB}
  sed -i'' "s@${SRC_HTTPS_CDN_URL}@${DEST_HTTPS_CDN_URL}@g" ${MRDB}
}

replaceGoogleAnalytics() {
  local MRDB=$1
  local SRC_G_ANALYTICS=$2
  local DEST_G_ANALYTICS=$3
  echo "Replacing Google Analytics code..."
  sed -i'' "s@${SRC_G_ANALYTICS}@${DEST_G_ANALYTICS}@g" ${MRDB}
}

searchReplaceMain() {
parseArgs $@
readProperties $SRC

SRC_URL=",'${URL}"
SRC_URL2=",'http://${URL}"
SRC_URL3=",'https://${URL}"
SRC_SHIB_URL=",'${SHIB_URL}'"
SRC_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"
SRC_G_ANALYTICS="${G_ANALYTICS}"
SRC_CDN_URL="${CDN_URL}"
SRC_HTTPS_CDN_URL="${HTTPS_CDN_URL}"

readProperties $DEST

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
      changeEnvInfo $MRDB $SRC_SHIB_URL $DEST_SHIB_URL $SRC_SHIB_LOGOUT_URL $DEST_SHIB_LOGOUT_URL

      if [ ! -z ${SRC_URL} ]; then
        replaceDomain $MRDB $SRC_URL $SRC_URL2 $SRC_URL3 $DEST_URL $DEST_URL2 $DEST_URL3
      fi

      if [ ! -z ${SRC_G_ANALYTICS} ] && [ "${SRC_G_ANALYTICS}" != "''" ]; then
        replaceGoogleAnalytics $MRDB $SRC_G_ANALYTICS $DEST_G_ANALYTICS
      fi

      if [ ! -z ${SRC_CDN_URL} ] && [ "${SRC_CDN_URL}" != "''" ] && [ ! -z ${SRC_HTTPS_CDN_URL} ] && [ "${SRC_HTTPS_CDN_URL}" != "''" ] ; then
        replaceCDNUrl $MRDB $SRC_CDN_URL $DEST_CDN_URL $SRC_HTTPS_CDN_URL $DEST_HTTPS_CDN_URL
      fi
    fi
  done
fi

# Get to root dir
cd ..
}

searchReplaceMain $@