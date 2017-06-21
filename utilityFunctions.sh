#!/bin/bash

setGlobalVariables() {
  EXPORT_DIR='db_export'
  MERGED_DIR='db_merged'
  IMPORT_SCRIPT='import.sh'
  EXPORT_SCRIPT='export.sh'
  MERGE_SCRIPT='merge.sh'
  SEARCH_REPLACE_SCRIPT='search_replace.sh'
  PUT_DB_SCRIPT='put_db.sh'
  AFTER_IMPORT_SCRIPT='after_import.sh'
  DROP_SQL_FILE='drop_tables'
  SUPER_ADMIN_TXT='superadmin_dev.txt'
  PARSE_FILE='parse_arguments.sh'
  READ_PROPERTIES_FILE='read_properties.sh'
  STRUCTURE_FILE='mirror_db_structure.sh'
  PROPERTIES_FILE='db.properties'
  PI_TOTAL_FILE='pi_total.txt'
  UTILITY_FILE='utilityFunctions.sh'
}

parseArgs() {
  if [ ! $# -ge 2 ]; then
      echo "Please enter the source or destination to run"
      exit 1
  fi

  while [ "$1" != "" ]; do
      case $1 in
        -s | --source)
          SRC=$2
          shift
          ;;
        -d | --destination)
          DEST=$2
          shift
          ;;
        --db-backup)
          DB_BACKUP=$2
          shift
          ;;
        -ebl )
          BATCH_LIMIT=$2
          shift
          ;;
        -pl )
          POOL_LIMIT=$2
          shift
          ;;
        -mbl )
          MERGE_BATCH_LIMIT=$2
          shift
          ;;
        -ewt )
          WAIT_TIME=$2
          shift
          ;;
        -iwt )
          IMPORT_WAIT_TIME=$2
          shift
          ;;
        -lf )
          LIST_FILE_NAME=$2
          shift
          ;;
        -dbf )
          DB_FILE_NAME=$2
          shift
          ;;
        -pf | --properties-file )
          PROPERTIES_FILE=$2
          shift
          ;;
        --blogid )
          BLOG_ID=$2
          shift
          ;;
        --site-url )
          SRC_URL=$2
          shift
          ;;
        --shib-url )
          SRC_SHIB_URL=$2
          shift
          ;;
        --g-analytics )
          SRC_G_ANALYTICS=$2
          shift
          ;;
        --force )
          FORCE_IMPORT=--force
          ;;
        --drop-tables)
          DROP_TABLES=true
          ;;
        --drop-tables-sql)
          DROP_TABLES_SQL=true
          ;;
        --skip-export)
          SKIP_EXPORT=true
          ;;
        --skip-import)
          SKIP_IMPORT=true
          ;;
        --skip-network-import)
          SKIP_NETWORK_IMPORT=true
          ;;
        --skip-replace)
          SKIP_REPLACE=true
          ;;
        --parallel-import)
          PARALLEL_IMPORT=true
          ;;
        --is-last-import)
          IS_LAST_IMPORT=true
          ;;
        --network-flag)
          NETWORK_FLAG=true
          ;;
        -- )
          shift;
          break
          ;;
        * )
          break
          ;;
      esac
      shift
  done
}

readProperties() {
  local domain=$1
	. db.properties

  DB_USER="${domain}_db_user"
  DB_USER=${!DB_USER}

  DB_PASSWORD="${domain}_db_pass"
  DB_PASSWORD=${!DB_PASSWORD}

  DB_HOST_NAME="${domain}_db_host"
  DB_HOST_NAME=${!DB_HOST_NAME}

  DB_SCHEMA="${domain}_db_name"
  DB_SCHEMA=${!DB_SCHEMA}

  URL="${domain}_url"
  URL=${!URL}

  HOST_NAME="${domain}_host"
  HOST_NAME=${!HOST_NAME}

  SITE_DIR="${domain}_dir"
  SITE_DIR=${!SITE_DIR}

  REMOTE_SCRIPT_DIR="${domain}_remote_dir"
  REMOTE_SCRIPT_DIR=${!REMOTE_SCRIPT_DIR}

  DB_BACKUP_DIR="${domain}_db_backup_dir"
  DB_BACKUP_DIR=${!DB_BACKUP_DIR}

  SHIB_URL="${domain}_shib_url"
  SHIB_URL=${!SHIB_URL}

  SHIB_LOGOUT_URL="${domain}_shib_logout_url"
  SHIB_LOGOUT_URL=${!SHIB_LOGOUT_URL}

  CDN_URL="${domain}_cdn_url"
  CDN_URL=${!CDN_URL}

  HTTPS_CDN_URL="${domain}_https_cdn_url"
  HTTPS_CDN_URL=${!HTTPS_CDN_URL}

  G_ANALYTICS="${domain}_g_analytics"
  G_ANALYTICS=${!G_ANALYTICS}

  # Set SSH Parameters
  SSH_KEY_PATH=$ssh_key_path
  SSH_USERNAME=$ssh_username
}

getWorkspace() {
  local workspace=$(pwd)
  echo $workspace
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

getDbName() {
  local dbtb=$1
  local dbName=$(echo ${dbtb} | sed 's/\./ /g' | awk '{print $1}')
  echo $dbName
}

getTbName() {
  local dbtb=$1
  local tbName=$(echo ${dbtb} | sed 's/\./ /g' | awk '{print $2}')
  echo $tbName
}

setFilePermissions() {
  echo "Changing right permissions for all bash scripts"
  chmod 750 *.sh
  chmod 754 $DROP_SQL_FILE.sql
  
}

getDb() {
  parseArgs $@
  readProperties $SRC

  if [ ! -z $DB_BACKUP ]; then
	DB_BACKUP_DIR=${DB_BACKUP}
  fi

  if [ ! "$PARALLEL_IMPORT" = true ]; then
	rsync -avzhe ssh --include '*.sql' --exclude '*' --delete --progress ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/
  else
	rsync -avzhe ssh --progress ${DB_BACKUP_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${DB_BACKUP_DIR}/ ${EXPORT_DIR}/
  fi
  # TODO: Need to fix DB_BACKUP_DIR being passed over to putDb() for syncing over Dest
  DB_BACKUP_DIR=${EXPORT_DIR}
}

createRemoteScriptDir() {
  local location=$1
  if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ ! -d ${REMOTE_SCRIPT_DIR} ]" ); then
  echo "Creating ${REMOTE_SCRIPT_DIR} on ${location}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir ${REMOTE_SCRIPT_DIR};"
  fi
}

uploadMirrorDbFiles() {
  local location=$1
  rsync -avzhe ssh --delete --progress ${STRUCTURE_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
  echo "Executing structure script for creating dir on ${location} server... "
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; ./${STRUCTURE_FILE} mk ${EXPORT_DIR}"
  rsync -avzhe ssh --delete --progress ${UTILITY_FILE} ${EXPORT_SCRIPT} ${MERGE_SCRIPT} ${PARSE_FILE} ${READ_PROPERTIES_FILE} ${PROPERTIES_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
}

removeMirrorDbFiles() {
  if ( ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "[ -d ${REMOTE_SCRIPT_DIR} ]" ); then
    echo "Removing ${REMOTE_SCRIPT_DIR} from ${SRC}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};"
  fi
}