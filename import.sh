#!/bin/bash

# Config Options

BACKUP_DIR='db_backup'
DROP_SQL_FILE='drop_tables'

. parse_arguments.sh

. read_properties.sh $DEST

# Drop all tables before import process
echo "Emptying Database..."
mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} < ${DROP_SQL_FILE}.sql

cd ${BACKUP_DIR}

# Disable foreign key check before importing
echo "Disabling foreign key check before importing db"
mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=0"

for MRDB in `ls *.sql`
do
	# Import statement
	echo "Starting to import ${MRDB}"
	mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} ${FORCE_IMPORT} < ${MRDB}
done

# Enable foreign key check after importing
echo "Enabling foreign key check after importing db"
mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} ${DB_SCHEMA} -e "SET foreign_key_checks=1"

cd ..