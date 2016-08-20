#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
DROP_SQL_FILE='drop_tables'
FORCE_IMPORT=""

. parse_arguments.sh

. read_properties.sh $DEST

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

	cd ..
	#drop all tables before import process
	echo "Emptying Database..."
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} < ${DROP_SQL_FILE}.sql
	
	cd ${BACKUP_DIR}

	echo "Starting to import database..."
	now=$(date +"%T")
	echo "Current time : $now "

	# Disable foreign key check before importing
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=0"

	#import statement
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${FORCE_IMPORT} ${DB_SCHEMA} < ${DB_FILE_NAME}.sql
	
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