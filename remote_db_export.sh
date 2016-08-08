#!/bin/bash

. db.properties

# Config Options
SRC=$1
REMOTE=$2
GROUP_COUNT=${3:-12}
WAIT_TIME=${4:-3}
FILE_NAME_TABLST='table_list.txt'
BACKUP_DIR='db_backup'


if [ "$REMOTE" == 'remote']
then
  MYSQL_PATH='/Applications/MAMP/Library/bin/'
else
  MYSQL_PATH=''
fi

if [ "$SRC" == 'prd' ]
then
  DB_USER=$prd_db_user
  DB_PASSWORD=$prd_db_pass
  DB_SCHEMA=$prd_db_name
  DB_HOST_NAME=$prd_db_host;
elif [ "$SRC" == 'nyudev' ]
then
  DB_USER=$dev_db_user
  DB_PASSWORD=$dev_db_pass
  DB_SCHEMA=$dev_db_name
  DB_HOST_NAME=$dev_db_host;
elif [ "$SRC" == 'sswtest' ]
then
  DB_USER=$sswtest_db_user
  DB_PASSWORD=$sswtest_db_pass
  DB_SCHEMA=$sswtest_db_name
  DB_HOST_NAME=$sswtest_db_host;
else
  echo "Source incorrectly specified"
  exit 1;
fi

# Empty BACKUP_DIR dir to remove any previous data
rm -rf ${BACKUP_DIR}
mkdir ${BACKUP_DIR}

cd ${BACKUP_DIR}

${MYSQL_PATH}mysql --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} -A --skip-column-names -e"SELECT CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) FROM information_schema.TABLES WHERE table_schema='${DB_SCHEMA}'" > ${FILE_NAME_TABLST}

echo "Starting to download DB... "
now=$(date +"%T")
echo "Current time : $now "

TOTAL=1
COMMIT_COUNT=0
COMMIT_LIMIT=GROUP_COUNT
for DBTB in `cat ${FILE_NAME_TABLST}`
do
	if [ ${COMMIT_COUNT} -eq 0 ]
	then
		echo "Starting new group of downloads... "
	fi
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    echo "Dowloading ${TB}.sql ... "
    ${MYSQL_PATH}mysqldump --host=${DB_HOST_NAME}  --user=${DB_USER} --password=${DB_PASSWORD} --hex-blob --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    (( COMMIT_COUNT++ ))
    (( TOTAL++ ))
    if [ ${COMMIT_COUNT} -eq ${COMMIT_LIMIT} ]
    then
        COMMIT_COUNT=0
        echo "Waiting to start new group... "
        sleep WAIT_TIME
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${COMMIT_COUNT} -gt 0 ]
then
    sleep 2
fi

# Get to root dir
cd ..

# Merge all tables to one mysql.sql
./merge.sh