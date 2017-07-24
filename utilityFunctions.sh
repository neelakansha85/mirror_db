#!/bin/bash

getWorkspace() {
  local workspace=$(pwd)
  echo $workspace
}

setGlobalVariables() {
  readonly EXPORT_DIR='db_export'
  readonly MERGED_DIR='db_merged'
  readonly IMPORT_SCRIPT='import.sh'
  readonly EXPORT_SCRIPT='export.sh'
  readonly MERGE_SCRIPT='merge.sh'
  readonly STRUCTURE_FILE='mirror_db_structure.sh'
  readonly UTILITY_FILE='utilityFunctions.sh'
  readonly DROP_SQL_FILE='drop_tables'
  readonly PI_TOTAL_FILE='pi_total.txt'
  readonly SUPER_ADMIN_TXT='superadmin_dev.txt'
  readonly LOGS_DIR='log'
  readonly WORKSPACE=$(getWorkspace)
}

setExportGlobalVariables() {
  # These variables are shared between export.sh and merge.sh files
  readonly EXPORT_DIR='db_export'
  readonly MERGED_DIR='db_merged'
  readonly LOGS_DIR='log'
  readonly PI_TOTAL_FILE='pi_total.txt'
  readonly POOL_WAIT_TIME=300
  readonly WORKSPACE=$(getWorkspace)
}

parseArgs() {
  if [ ! $# -ge 2 ]; then
      echo "Please enter the source or destination to run"
      exit 1
  fi

  while [ "$1" != "" ]; do
      case $1 in
        -s | --source )
          SRC=$2
          shift
          ;;
        -d | --destination )
          DEST=$2
          shift
          ;;
        --db-backup-dir )
          CUSTOM_DB_BACKUP_DIR=$2
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
          CUSTOM_LIST_FILE_NAME=$2
          shift
          ;;
        -dbf )
          CUSTOM_DB_FILE_NAME=$2
          shift
          ;;
        -pf | --properties-file )
          PROPERTIES_FILE=$2
          shift
          ;;
        --blog-id )
          # TODO: Need to remove below condition once all files are cleaned
          if [ ! -z $2 ]; then
            BLOG_ID=$2
            shift
          fi
          ;;
        --force)
          FORCE_IMPORT=--force
          ;;
        --drop-tables)
          DROP_TABLES=true
          ;;
        --drop-tables-sql)
          DROP_TABLE_SQL=true
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

  if [ -z $REMOTE_SCRIPT_DIR ]; then
    REMOTE_SCRIPT_DIR='mirror_db'
  fi
  if [ -z $DB_BACKUP_DIR ]; then
    DB_BACKUP_DIR='db_backup'
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
  local dbBackDir=$1
  if [ ! "$PARALLEL_IMPORT" = true ]; then
	  rsync -avzhe ssh --include '*.sql' --exclude '*' --delete --progress ${SSH_USERNAME}@${HOST_NAME}:${dbBackDir}/ ${EXPORT_DIR}/
  else
	  rsync -avzhe ssh --progress ${dbBackDir}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${dbBackDir}/ ${EXPORT_DIR}/
  fi
  #since db is copied to mirror_db server, setting value to EXPORT_DIR
  readonly MIRROR_DB_BACKUP_DIR=$EXPORT_DIR
}

putDb() {
  local dbBackDir=$1
  if [ ! "$PARALLEL_IMPORT" = true ]; then
    echo "Database path on mirror_db: $dbBackDir"
	  rsync -avzhe ssh --include '*.sql' --exclude '*'  --delete --progress ${dbBackDir}/ ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/
  else
	  rsync -avzhe ssh --progress ${EXPORT_DIR}/${DB_FILE_NAME} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/${EXPORT_DIR}/
  fi
}

createRemoteScriptDir() {
  local location=$1
  echo "Creating ${REMOTE_SCRIPT_DIR} on ${location}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "mkdir -p ${REMOTE_SCRIPT_DIR};"
}

prepareForDist() {
  DIST_DIR=distFolder
  mkdir -p $DIST_DIR
  cd $DIST_DIR
  cp ${UTILITY_FILE} ${EXPORT_SCRIPT} ${MERGE_SCRIPT} ${PROPERTIES_FILE} ${IMPORT_SCRIPT} ${SUPER_ADMIN_TXT} .
  #setting file permissions
  setFilePermissions
  cd $WORKSPACE
}

uploadMirrorDbFiles() {
  local location=$1
  rsync -avzhe ssh --delete --progress ${STRUCTURE_FILE} ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
  echo "Executing structure script for creating dir on ${location} server... "
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm -rf *; mkdir -p ${EXPORT_DIR}"
  rsync -avzhe ssh --delete --progress ${DIST_DIR}/* ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
}

removeMirrorDbFiles() {
  local location=$1
  echo "Removing ${REMOTE_SCRIPT_DIR} from ${location}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};"
}
