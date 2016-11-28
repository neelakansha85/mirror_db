#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
DROP_SQL_FILE='drop_tables'

. parse_arguments.sh

. read_properties.sh $DEST

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