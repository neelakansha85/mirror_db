#!/bin/bash

# Config/Default Options
REMOTE_SCRIPT_DIR='mirror_db'
EXPORT_DIR='db_export'
MERGED_DIR='db_merged'
DB_BACKUP_DIR='db_backup'
DB_SUFFIX=''

. parse_arguments.sh

checkArguments(){
    if [[ ! $? == 0 ]]; then
        echo "FAILURE: Error parsing arguments!"
    fi
}

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
    local tabledetail=$1
    local DbName=$(echo ${tabledetail} | sed 's/\./ /g' | awk '{print $1}')
    echo $DbName
}

getTbName(){
    local tabledetail=$1
    local TbName=$(echo ${tabledetail} | sed 's/\./ /g' | awk '{print $1}')
    echo $TbName
}

mergeFile(){

    echo "Starting to merge DB to ${DB_FILE_NAME}... "
    now=$(date +"%T")
    echo "Current time : $now "

    TOTAL=1
    MERGE_BATCH_COUNT=1

    for DBTB in `cat ${LIST_FILE_NAME}`
    do
        DB=$(getDbName $DBTB)
        TB=$(getTbName $DBTB)
        gunzip ${DB}_${TB}.sql.gz

        mergedFileName=$(mergeFileName $TOTAL)

        `cat ${DB}_${TB}.sql >> ${mergedFileName}`
	    echo "" >> ${mergedFileName}
	    `rm ${DB}_${TB}.sql`
	    (( MERGE_BATCH_COUNT++ ))
        checkBatchLimit
    done
    moveFileToDir
    echo "Completed merging DB to ${DB_FILE_NAME}... "
    echo "Total no of merged sql files = ${TOTAL}"
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
checkBatchLimit(){
         if [ ${MERGE_BATCH_COUNT} -eq ${MERGE_BATCH_LIMIT} ]; then
               moveFileToDir
               MERGE_BATCH_COUNT=1
               (( TOTAL++ ))
               echo "Merged ${MERGE_BATCH_LIMIT} tables, starting new batch for merging... "
         fi
}

moveFileToDir(){
    if [ -e ${mergedFileName} ]; then
    mv ${mergedFileName} $MERGED_DIR/${mergedFileName}
    fi
}

archiveMergedFiles(){
    echo "Copying all merged DB files to archives dir... "
    for MRDB in `ls ${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/${MERGED_DIR}/*.sql`
    do
        cp ${MRDB} ${DB_BACKUP_DIR}/${DB_FILE_N}/
    done
}

#starts here
. parse_arguments.sh
checkArguments

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
     DB_FILE_N=`echo ${DB_FILE_N} | cut -d '_' -f-2`
fi

createFile_N_Dir

# Get to Home Dir
cd ..

archiveMergedFiles


