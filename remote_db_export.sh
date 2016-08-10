#!/bin/bash

. db.properties

# Config Options
SRC=$1
REMOTE=$2
BATCH_LIMIT=${3:-10}
WAIT_TIME=${4:-3}
FILE_NAME_TABLST='table_list.txt'
BACKUP_DIR='db_backup'
POOL_LIMIT=7000
POOL_WAIT_TIME=300


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
BATCH_COUNT=0
POOL_COUNT=0

for DBTB in `cat ${FILE_NAME_TABLST}`
do
	if [ ${POOL_COUNT} -eq 0 ]
	then
		echo "Starting a new pool of downloads... "
	fi
	if [ ${BATCH_COUNT} -eq 0 ]
	then
		echo "Starting new batch of downloads... "
	fi
    DB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $1}'`
    TB=`echo ${DBTB} | sed 's/\./ /g' | awk '{print $2}'`
    echo "Dowloading ${TB}.sql ... "
    ${MYSQL_PATH}mysqldump --host=${DB_HOST_NAME} --user=${DB_USER} --password=${DB_PASSWORD} --hex-blob --single-transaction --quick --triggers ${DB} ${TB} | gzip > ${DB}_${TB}.sql.gz &
    (( BATCH_COUNT++ ))
    (( POOL_COUNT++ ))
    (( TOTAL++ ))
    if [ ${BATCH_COUNT} -eq ${BATCH_LIMIT} ]
    then
        BATCH_COUNT=0
        echo "Waiting to start new batch... "
        sleep $WAIT_TIME
    fi
    if [ ${POOL_COUNT} -eq ${POOL_LIMIT} ]
    then
        POOL_COUNT=0
        echo "Waiting to start new pool... "
        sleep $POOL_WAIT_TIME
    fi
done

echo "Completed downloading DB... "
echo "Total no of tables downloaded = ${TOTAL}"
now=$(date +"%T")
echo "Current time : $now "

if [ ${BATCH_COUNT} -gt 0 ]
then
    sleep 2
fi

# Get to root dir
cd ..

# Merge all tables to one mysql.sql
./merge.sh