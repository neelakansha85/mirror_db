#!/bin/bash

# Config Options
FILE_NAME_TABLST==${1:-table_list.txt}
DB_FILE_NAME==${2:-mysql.sql}

cd db_backup

gunzip *.sql.gz

echo "Merging all tables to one ${DB_FILE_NAME}.sql ... "

for DBTB in `cat ${FILE_NAME_TABLST}`
do
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    `cat ${TB} >> ${DB_FILE_NAME}`
	echo "" >> ${DB_FILE_NAME}
	`rm ${TB}.sql`
done

