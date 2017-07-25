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
          readonly SRC=$2
          shift
          ;;
        -d | --destination )
          readonly DEST=$2
          shift
          ;;
        --db-backup-dir )
          readonly CUSTOM_DB_BACKUP_DIR=$2
          shift
          ;;
        -ebl )
          readonly BATCH_LIMIT=$2
          shift
          ;;
        -pl )
          readonly POOL_LIMIT=$2
          shift
          ;;
        -mbl )
          readonly MERGE_BATCH_LIMIT=$2
          shift
          ;;
        -ewt )
          readonly WAIT_TIME=$2
          shift
          ;;
        -iwt )
          readonly IMPORT_WAIT_TIME=$2
          shift
          ;;
        -lf )
          readonly LIST_FILE_NAME=$2
          shift
          ;;
        -dbf )
          readonly DB_FILE_NAME=$2
          shift
          ;;
        -pf | --properties-file )
          readonly PROPERTIES_FILE=$2
          shift
          ;;
        --blog-id )
          # TODO: Need to remove below condition once all files are cleaned
          if [ ! -z $2 ]; then
            readonly BLOG_ID=$2
            shift
          fi
          ;;
        --force)
          readonly FORCE_IMPORT=--force
          ;;
          # Below constants are modified in checkFlags()
        --drop-tables)
          DROP_TABLES=true
          ;;
        --drop-tables-sql)
          DROP_TABLE_SQL=true
          ;;
        --skip-export)
          readonly SKIP_EXPORT=true
          ;;
        --skip-import)
          readonly SKIP_IMPORT=true
          ;;
        --skip-network-import)
          readonly SKIP_NETWORK_IMPORT=true
          ;;
        --skip-replace)
          readonly SKIP_REPLACE=true
          ;;
        --parallel-import)
          readonly PARALLEL_IMPORT=true
          ;;
        --is-last-import)
          readonly IS_LAST_IMPORT=true
          ;;
        --network-flag)
          readonly NETWORK_FLAG=true
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

  # Setting Defaults
  if [ -z $PROPERTIES_FILE ]; then
    readonly PROPERTIES_FILE='db.properties'
  fi
  if [ -z $BATCH_LIMIT ]; then
    readonly BATCH_LIMIT=10
  fi
  if [ -z $POOL_LIMIT ]; then
    readonly POOL_LIMIT=7000
  fi
  if [ -z $MERGE_BATCH_LIMIT ]; then
    readonly MERGE_BATCH_LIMIT=7000
  fi
  if [ -z $WAIT_TIME ]; then
    readonly WAIT_TIME=3
  fi
  if [ -z $IMPORT_WAIT_TIME ]; then
    readonly IMPORT_WAIT_TIME=180
  fi
  if [ -z $LIST_FILE_NAME ]; then
    readonly LIST_FILE_NAME="table_list.txt"
  fi
  if [ -z $DB_FILE_NAME ]; then
    if [ ! -z $SRC ]; then
      readonly DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d_%H%M%S").sql"
    else
      readonly DB_FILE_NAME="mysql_$(date +"%Y-%m-%d_%H%M%S").sql"
    fi
  fi
}

exportParseArgs() {
  while [ "$1" != "" ]; do
      case $1 in
        -s | --source )
          readonly SRC=$2
          shift
          ;;
        -d | --destination )
          readonly DEST=$2
          shift
          ;;
        -ebl )
          readonly BATCH_LIMIT=$2
          shift
          ;;
        -pl )
          readonly POOL_LIMIT=$2
          shift
          ;;
        -ewt )
          readonly WAIT_TIME=$2
          shift
          ;;
        ## Below 3 flags are being reassigned by export and merge
        ## both on SRC server and hence can not be declared as readonly.
        -mbl )
          MERGE_BATCH_LIMIT=$2
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
        --parallel-import)
          readonly PARALLEL_IMPORT=true
          ;;
        --blog-id )
          # TODO: Need to remove below condition once all files are cleaned
          if [ ! -z $2 ]; then
            readonly BLOG_ID=$2
            shift
          fi
          ;;
        --network-flag )
          readonly NETWORK_FLAG=true
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

  if [ -z $BATCH_LIMIT ]; then
    readonly BATCH_LIMIT=10
  fi
  if [ -z $POOL_LIMIT ]; then
    readonly POOL_LIMIT=7000
  fi
  if [ -z $MERGE_BATCH_LIMIT ]; then
    MERGE_BATCH_LIMIT=7000
  fi
  if [ -z $WAIT_TIME ]; then
    readonly WAIT_TIME=3
  fi
  if [ -z $LIST_FILE_NAME ]; then
    LIST_FILE_NAME="table_list.txt"
  fi
  if [ -z $DB_FILE_NAME ]; then
    if [ ! -z $SRC ]; then
      DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d").sql"
    else
      DB_FILE_NAME="mysql_$(date +"%Y-%m-%d").sql"
    fi
  fi
}

importParseArgs() {
  while [ "$1" != "" ]; do
      case $1 in
        -s | --source )
          readonly SRC=$2
          shift
          ;;
        -d | --destination )
          readonly DEST=$2
          shift
          ;;
        -dbf )
          readonly DB_FILE_NAME=$2
          shift
          ;;
        -iwt )
          readonly IMPORT_WAIT_TIME=$2
          shift
          ;;
        --force)
          readonly FORCE_IMPORT=--force
          ;;
        --skip-replace)
          readonly SKIP_REPLACE=true
          ;;
        --skip-import)
          readonly SKIP_IMPORT=true
          ;;
        --drop-tables-sql)
          readonly DROP_TABLE_SQL=true
          ;;
        * )
          break
          ;;
      esac
      shift
  done

  if [ -z $IMPORT_WAIT_TIME ]; then
    readonly IMPORT_WAIT_TIME=180
  fi
  if [ -z $DB_FILE_NAME ]; then
    if [ ! -z $SRC ]; then
      DB_FILE_NAME="${SRC}_$(date +"%Y-%m-%d").sql"
    else
      DB_FILE_NAME="mysql_$(date +"%Y-%m-%d").sql"
    fi
  fi
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
  cp ${UTILITY_FILE} ${EXPORT_SCRIPT} ${MERGE_SCRIPT} ${PROPERTIES_FILE} ${IMPORT_SCRIPT} ${SUPER_ADMIN_TXT} ${DROP_SQL_FILE}.sql ${DIST_DIR}
  cd $DIST_DIR
  echo "Changing right permissions for all bash scripts"
  setFilePermissions
  cd $WORKSPACE
}

uploadMirrorDbFiles() {
  local location=$1
  echo "Executing structure script for creating dir on ${location} server... "
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "cd ${REMOTE_SCRIPT_DIR}; rm -rf *; mkdir -p ${EXPORT_DIR}"
  rsync -avzhe ssh --delete --progress ${DIST_DIR}/* ${SSH_USERNAME}@${HOST_NAME}:${REMOTE_SCRIPT_DIR}/
}

removeMirrorDbFiles() {
  local location=$1
  echo "Removing ${REMOTE_SCRIPT_DIR} from ${location}..."
  ssh -i ${SSH_KEY_PATH} ${SSH_USERNAME}@${HOST_NAME} "rm -rf ${REMOTE_SCRIPT_DIR};"
}
