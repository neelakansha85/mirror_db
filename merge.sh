#!/bin/bash

set -x

. parse_arguments.sh

# Config/Default Options
readonly REMOTE_SCRIPT_DIR='mirror_db'
readonly EXPORT_DIR='db_export'
readonly MERGED_DIR='db_merged'
readonly DB_BACKUP_DIR='db_backup'
readonly DB_SUFFIX=''

getFileName() {
    local file=$1
    local fileName=$(echo ${file} | sed 's/\./ /g' | awk '{print $1}')
    echo $fileName
}

getFileExtension() {
    local file=$1
    local fileExtension=$(echo ${file} | sed 's/\./ /g' | awk '{print $2}')
    echo $fileExtension
}

createMergeDir() {
    mkdir -p $MERGED_DIR
}

createBackupDir(){
    mkdir -p $DB_BACKUP_DIR
}

createFile_N_Dir(){
    mkdir -p $DB_FILE_N
}

getDbName(){
    local dbtb=$1
    local dbName=$(echo ${dbtb} | sed 's/\./ /g' | awk '{print $1}')
    echo $dbName
}

getTbName(){
    local dbtb=$1
    local tbName=$(echo ${dbtb} | sed 's/\./ /g' | awk '{print $1}')
    echo $tbName
}

mergeFile(){

    echo "Starting to merge DB to ${DB_FILE_NAME}... "
    now=$(date +"%T")
    echo "Current time : $now "

    total=1
    mergeBatchCount=1

    for dbtb in $(cat ${LIST_FILE_NAME})
    do
        db=$(getDbName $dbtb)
        tb=$(getTbName $dbtb)
        gunzip ${db}_${tb}.sql.gz

        mergedFileName=$(mergeFileName $total)

        $(cat ${db}_${tb}.sql >> ${mergedFileName})
	    echo "" >> ${mergedFileName}
	    $(rm ${db}_${tb}.sql)
	    (( mergeBatchCount++ ))

        if [ ${mergeBatchCount} -eq ${MERGE_BATCH_LIMIT} ]; then
               moveFileToDir
               mergeBatchCount=1
               (( total++ ))
               echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
         fi
    done
    moveFileToDir
    echo "Completed merging DB to ${DB_FILE_NAME}... "
    echo "Total no of merged sql files = ${total}"
    now=$(date +"%T")
    echo "Current time : $now "
}

mergeFileName(){
    local total=$1
    if [ ! "$PARALLEL_IMPORT" = true ]; then
        DB_SUFFIX="_${total}"
    fi

    mergedName="${DB_FILE_N}${DB_SUFFIX}.${DB_FILE_EXT}"
    echo $mergedName
}

moveFileToDir(){
    if [ -e ${mergedFileName} ]; then
    mv ${mergedFileName} $MERGED_DIR/${mergedFileName}
    fi
}

archiveMergedFiles(){
    echo "Copying all merged DB files to archives dir... "
    for mrdb in $(ls ${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/${MERGED_DIR}/*.sql)
    do
        cp ${mrdb} ${DB_BACKUP_DIR}/${DB_FILE_N}/
    done
}

#starts here
parseArgs $@

DB_FILE_EXT=$(getFileExtension $DB_FILE_NAME)
DB_FILE_N=$(getFileName $DB_FILE_NAME)

cd ${EXPORT_DIR}
createMergeDir
mergeFile

# Get to Home Dir
cd ~

# Move all .sql files to archives dir for future reference

createBackupDir
cd ${DB_BACKUP_DIR}

if [[ $DB_FILE_N =~ .*_network.* ]]; then
     DB_FILE_N=$(echo ${DB_FILE_N} | cut -d '_' -f-2)
fi

createFile_N_Dir

# Get to Home Dir
cd ..
archiveMergedFiles


