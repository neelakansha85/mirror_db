#!/bin/bash

DB_HOST_NAME="vps-nyu-prod-us-east-1d.cluster-czvuylgsbq58.us-east-1.rds.amazonaws.com"
DB_USER="db_dom18847"
DB_PASSWORD="43Vmv4k3taB7CYx89jSKDCsvYgULxjVwNNwvhAOM"
DB_SCHEMA="db_dom18847"
IMPORT_WAIT_TIME=2

BACKUP_DIR="db_archives/prd_2016-11-27"

SRC_URL="wp.nyu.edu"
OLD_URL1=",'wp.nyu.edu"
OLD_URL2=",'http://wp.nyu.edu"
OLD_URL3=",'https://wp.nyu.edu"
OLD_SHIB_URL=",'https://wp.nyu.edu/Shibboleth.sso/Login'"
OLD_SHIB_LOGOUT_URL=",'https://wp.nyu.edu/Shibboleth.sso/Logout?return=https://shibboleth.nyu.edu/idp/profile/Logout'"
SRC_G_ANALYTICS="UA-49482334-1"

NEW_URL1=",'wpdev.nyu.edu"
NEW_URL2=",'http://wpdev.nyu.edu"
NEW_URL3=",'https://wpdev.nyu.edu"
NEW_SHIB_URL=",'https://wpdev.nyu.edu/Shibboleth.sso/Login'"
NEW_SHIB_LOGOUT_URL=",'https://wpdev.nyu.edu/Shibboleth.sso/Logout?return=https://shibbolethqa.es.its.nyu.edu/idp/profile/Logout'"
G_ANALYTICS="UA-00000000-1"

cd ${BACKUP_DIR}

# for MRDB in `ls *.sql`
# do
#   if [ -e ${MRDB} ]; then
#     echo "File ${MRDB} found..."
#     echo "Changing environment specific information"
#     if [ ! -z ${OLD_SHIB_URL} ] && [ "${OLD_SHIB_URL}" != "''" ]; then
#       # Replace Shib Production with Shib QA 
#       echo "Replacing Shibboleth URL..."
#       sed -i'' "s@${OLD_SHIB_URL}@${NEW_SHIB_URL}@g" ${MRDB}
#       sed -i'' "s@${OLD_SHIB_LOGOUT_URL}@${NEW_SHIB_LOGOUT_URL}@g" ${MRDB}
#     fi

#     if [ ! -z ${SRC_URL} ]; then
#       # Replace old domain with the new domain
#       echo "Replacing Site URL..."
#       echo "Running -> sed -i'' \"s@${OLD_URL1}@${NEW_URL1}@g\" ${MRDB} ${MRDB}"
#       sed -i'' "s@${OLD_URL1}@${NEW_URL1}@g" ${MRDB}

#       echo "Running -> sed -i'' \"s@${OLD_URL2}@${NEW_URL2}@g\" ${MRDB}"
#       sed -i'' "s@${OLD_URL2}@${NEW_URL2}@g" ${MRDB}

#       echo "Running -> sed -i'' \"s@${OLD_URL3}@${NEW_URL3}@g\" ${MRDB}"
#       sed -i'' "s@${OLD_URL3}@${NEW_URL3}@g" ${MRDB}
      
#     fi

#     if [ ! -z ${SRC_G_ANALYTICS} ] && [ "${SRC_G_ANALYTICS}" != "''" ]; then
#       echo "Replacing Google Analytics code..."
#       sed -i'' "s@${SRC_G_ANALYTICS}@${G_ANALYTICS}@g" ${MRDB}
#     fi
#   fi
# done


# Disable foreign key check before importing
echo "Disabling foreign key check before importing db"
mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=0"

  for MRDB in `ls *.sql`
  do
    # Import statement
    echo "Starting to import ${MRDB}"
    mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} ${FORCE_IMPORT} < ${MRDB}
    sleep $IMPORT_WAIT_TIME
  done


# Enable foreign key check after importing
echo "Enabling foreign key check after importing db"
mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=1"


