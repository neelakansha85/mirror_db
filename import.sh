#!/bin/bash

# Config Options

#DEST=$1
#DB_FILE_NAME=${2:-'mysql'}
ARCHIVE_DIR='archives'
DROP_SQL_FILE='drop_tables'

. parse_arguments.sh

. read_properties.sh $DEST

#go to archive directory to import sql file
if [ ! -d "$ARCHIVES_DIR" ]; then
  mkdir $ARCHIVES_DIR
fi

cd ${ARCHIVE_DIR}

if [ -e $DB_FILE_NAME.sql ]; then
	#MYSQL_PATH='C:/wamp/bin/mysql/mysql5.7.9/bin'
	echo "File ${DB_FILE_NAME}.sql found..."

	echo "Changing environment specific information"
	#Replace ${RPLC_SRC_URL} to ${DEST_URL} in consolidated sql file
	# Replace old domain with the new domain
	echo "Replacing ${RPLC_SRC_URL} to ${RPLC_DEST_URL}..."
	echo "Running -> sed -i'' 's/'${SRC_URL}'/'${URL}'/g' ${DB_FILE_NAME}.sql"
	sed -i'' 's/'${SRC_URL}'/'${URL}'/g' ${DB_FILE_NAME}.sql

	# Replace Shib Production with Shib QA 
	echo "Running -> sed -i'' 's/'${SRC_SHIB_URL}'/'${SHIB_URL}'/g' ${DB_FILE_NAME}.sql"
	sed -i'' 's/'${SRC_SHIB_URL}'/'${SHIB_URL}'/g' ${DB_FILE_NAME}.sql
	
	echo "Running ->sed -i'' 's/'${SRC_G_ANALYTICS}'/'${G_ANALYTICS}'/g' ${DB_FILE_NAME}.sql"
	sed -i'' 's/'${SRC_G_ANALYTICS}'/'${G_ANALYTICS}'/g' ${DB_FILE_NAME}.sql

	cd ..
	#drop all tables before import process
	echo "Emptying Database..."
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} < ${DROP_SQL_FILE}.sql
	
	cd ${ARCHIVE_DIR}

	echo "Starting to import database..."
	now=$(date +"%T")
	echo "Current time : $now "

	# Disable foreign key check before importing
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=0"

	#import statement
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} < ${DB_FILE_NAME}.sql
	
	# Enable foreign key check after importing
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=1"

	echo "Database imported successfully..."
	now=$(date +"%T")
    echo "Current time : $now "

else
	echo "No file present. Please check file is within the directory"
	exit 1
fi

cd ..