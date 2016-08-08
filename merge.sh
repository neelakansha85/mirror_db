#!/bin/bash

# Config Options
FILE_NAME_TABLST==${1:-table_list.txt}
DB_FILE_NAME==${2:-mysql}

cd db_backup

gunzip *.sql.gz

echo "Merging all tables to one ${DB_FILE_NAME}.sql ... "

for DBTB in `cat ${FILE_NAME_TABLST}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    `cat ${DB}_${TB}.sql >> ${DB_FILE_NAME}.sql`
	echo "" >> ${DB_FILE_NAME}
	`rm ${DB}_${TB}.sql`
done

