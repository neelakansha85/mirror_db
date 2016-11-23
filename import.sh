#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
DROP_SQL_FILE='drop_tables'

. parse_arguments.sh

. read_properties.sh $DEST

OLD_URL1=",'${SRC_URL}"
OLD_URL2=",'http://${SRC_URL}"
OLD_URL2=",'https://${SRC_URL}"
OLD_SHIB_URL=",'${SRC_SHIB_URL}'"
OLD_SHIB_LOGOUT_URL=",'${SRC_SHIB_LOGOUT_URL}'"

NEW_URL1=",'${URL}"
NEW_URL2=",'http://${URL}"
NEW_URL3=",'https://${URL}"
NEW_SHIB_URL=",'${SHIB_URL}'"
NEW_SHIB_LOGOUT_URL=",'${SHIB_LOGOUT_URL}'"

#Replacing Values from old domain to new domain
cd ${BACKUP_DIR}

if [ ! "$SKIP_REPLACE" = true ]; then
  for MRDB in `ls *.sql`
  do
    if [ -e ${MRDB} ]; then
      echo "File ${MRDB} found..."
      echo "Changing environment specific information"
      if [ ! -z ${OLD_SHIB_URL} ] && [ "${OLD_SHIB_URL}" != "''" ]; then
        # Replace Shib Production with Shib QA 
        echo "Replacing Shibboleth URL..."
        sed -i'' "s@${OLD_SHIB_URL}@${NEW_SHIB_URL}@g" ${MRDB}
        sed -i'' "s@${OLD_SHIB_LOGOUT_URL}@${NEW_SHIB_LOGOUT_URL}@g" ${MRDB}
      fi

      if [ ! -z ${SRC_URL} ]; then
        # Replace old domain with the new domain
        echo "Replacing Site URL..."
        echo "Running -> sed -i'' \"s@${OLD_URL1}@${NEW_URL1}@g\" ${MRDB} ${MRDB}"
        sed -i'' "s@${OLD_URL1}@${NEW_URL1}@g" ${MRDB}

        echo "Running -> sed -i'' \"s@${OLD_URL2}@${NEW_URL2}@g\" ${MRDB}"
        sed -i'' "s@${OLD_URL2}@${NEW_URL2}@g" ${MRDB}

        echo "Running -> sed -i'' \"s@${OLD_URL3}@${NEW_URL3}@g\" ${MRDB}"
        sed -i'' "s@${OLD_URL3}@${NEW_URL3}@g" ${MRDB}
        
      fi

      if [ ! -z ${SRC_G_ANALYTICS} ] && [ "${SRC_G_ANALYTICS}" != "''" ]; then
        echo "Replacing Google Analytics code..."
        sed -i'' "s@${SRC_G_ANALYTICS}@${G_ANALYTICS}@g" ${MRDB}
      fi
    fi
  done
fi

# Get to root dir
cd ..

# Drop all tables using sql procedure before import process
if [ "$DROP_TABLES_SQL" = true ]; then
	echo "Emptying Database using sql procedure..."
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} < ${DROP_SQL_FILE}.sql
fi

cd ${BACKUP_DIR}

if [ ! "$SKIP_IMPORT" = true ]; then

	# Disable foreign key check before importing
	echo "Disabling foreign key check before importing db"
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=0"

	if [ ! -z $DB_FILE_NAME ]; then
			# Import statement
			echo "Starting to import ${DB_FILE_NAME}"
			mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} ${FORCE_IMPORT} < ${DB_FILE_NAME}
			# Remove file to avoid importing it twice
			rm $DB_FILE_NAME
	else
		# Scan for all *.sql files to import 
		for MRDB in `ls *.sql`
		do
			# Import statement
			echo "Starting to import ${MRDB}"
			mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} ${FORCE_IMPORT} < ${MRDB}
			sleep $IMPORT_WAIT_TIME
		done
	fi

	# Enable foreign key check after importing
	echo "Enabling foreign key check after importing db"
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=1"
fi

cd ..