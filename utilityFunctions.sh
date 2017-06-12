#!/bin/bash

set -e

parseArgs() {
  if [ ! $# -ge 2 ]; then
      echo "Please enter the source or destination to run"
      exit 1
  fi

  while [ "$1" != "" ]; do
      case $1 in
        -s | --source)
          local SRC=$2
          shift
          ;;
        -d | --destination)
          local DEST=$2
          shift
          ;;
        --db-backup)
          local DB_BACKUP=$2
          shift
          ;;
        -ebl )
          local BATCH_LIMIT=$2
          shift
          ;;
        -pl )
          local POOL_LIMIT=$2
          shift
          ;;
        -mbl )
          local MERGE_BATCH_LIMIT=$2
          shift
          ;;
        -ewt )
          local WAIT_TIME=$2
          shift
          ;;
        -iwt )
          local IMPORT_WAIT_TIME=$2
          shift
          ;;
        -lf )
          local listFile=$2
          shift
          ;;
        -dbf )
          local dbFile=$2
          shift
          ;;
        -pf | --properties-file )
          local PROPERTIES_FILE=$2
          shift
          ;;
        --blogid )
          local BLOG_ID=$2
          shift
          ;;
        --site-url )
          local SRC_URL=$2
          shift
          ;;
        --shib-url )
          local SRC_SHIB_URL=$2
          shift
          ;;
        --g-analytics )
          local SRC_G_ANALYTICS=$2
          shift
          ;;
        --force )
          local FORCE_IMPORT=--force
          ;;
        --drop-tables)
          local DROP_TABLES=true
          ;;
        --drop-tables-sql)
          local DROP_TABLES_SQL=true
          ;;
        --skip-export)
          local SKIP_EXPORT=true
          ;;
        --skip-import)
          local SKIP_IMPORT=true
          ;;
        --skip-network-import)
          local SKIP_NETWORK_IMPORT=true
          ;;
        --skip-replace)
          local SKIP_REPLACE=true
          ;;
        --parallel-import)
          local PARALLEL_IMPORT=true
          ;;
        --is-last-import)
          local IS_LAST_IMPORT=true
          ;;
        --network-flag)
          local NETWORK_FLAG=true
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