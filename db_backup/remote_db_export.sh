#!/bin/bash

cd ..
. db.properties

src=$1

if [ "$src" == 'prd' ]
then
  DB_USER=$prd_db_user
  DB_PASSWORD=$prd_db_pass
  DB_SCHEMA=$prd_db_name
  DB_HOST_NAME=$prd_db_host;
elif [ "$src" == 'nyudev' ]
then
  DB_USER=$dev_db_user
  DB_PASSWORD=$dev_db_pass
  DB_SCHEMA=$dev_db_name
  DB_HOST_NAME=$dev_db_host;
elif [ "$src" == 'sswtest' ]
then
  DB_USER=$sswtest_db_user
  DB_PASSWORD=$sswtest_db_pass
  DB_SCHEMA=$sswtest_db_name
  DB_HOST_NAME=$sswtest_db_host;
else
  echo "Source incorrectly specified"
  exit 1;
fi

cd db_backup

FILE_NAME_TABLST='table_list.txt'

/Applications/MAMP/Library/bin/mysql --host=${DB_HOST_NAME}  --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}'" > ${FILE_NAME_TABLST}

echo "Starting to download DB... "
now=$(date +"%T")
echo "Current time : $now "

TOTAL=1
COMMIT_COUNT=0
COMMIT_LIMIT=10
for DBTB in `cat ${FILE_NAME_TABLST}`
do
    echo "Starting to download new group... "
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    /Applications/MAMP/Library/bin/mysqldump --host=${DB_HOST_NAME}  --user=${DB_USER} --password=${DB_PASSWORD} --hex-blob --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    (( COMMIT_COUNT++ ))
    (( TOTAL++ ))
    if [ ${COMMIT_COUNT} -eq ${COMMIT_LIMIT} ]
    then
        COMMIT_COUNT=0
        echo "Waiting to start new group... "
        sleep 4
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${COMMIT_COUNT} -gt 0 ]
then
    sleep 5
fi