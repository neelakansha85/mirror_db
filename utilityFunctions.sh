#!/bin/bash

getWorkspace() {
  local workspace=$(pwd)
  echo $workspace
}

setGlobalVariables() {
  readonly exportDir='db_export'
  readonly mergedDir='db_merged'
  readonly importScript='import.sh'
  readonly exportScript='export.sh'
  readonly mergeScript='merge.sh'
  readonly structureFile='mirror_db_structure.sh'
  readonly utilityFile='utilityFunctions.sh'
  readonly dropSqlFile='drop_tables'
  readonly PiTotalFile='pi_total.txt'
  readonly superAdminTxt='superadmin_dev.txt'
  readonly logsDir='log'
  readonly workspace=$(getWorkspace)
  #properties file can be changed during execution hence not made readonly
  propertiesFile='db.properties'

  batchLimit=10
  poolLimit=7000
  mergeBatchLimit=7000
  waitTime=3
  importWaitTime=180
  srcUrl="''"
  srcShibUrl="''"
  srcGAnalytics="''"
  blogId="''"
  # not changing below variables due to similarities in naming of global and local in export.sh, wanted to discuss before proceeding
  LIST_FILE_NAME='table_list.txt'
  DB_FILE_NAME="mysql_$(date +"%Y-%m-%d").sql"
}

parseArgs() {
  if [ ! $# -ge 2 ]; then
      echo "Please enter the source or destination to run"
      exit 1
  fi

  while [ "$1" != "" ]; do
      case $1 in
        -s | --source)
          src=$2
          shift
          ;;
        -d | --destination)
          dest=$2
          shift
          ;;
        --db-backup-dir)
          customDbBackupDir=$2
          shift
          ;;
        -ebl )
          batchLimit=$2
          shift
          ;;
        -pl )
          poolLimit=$2
          shift
          ;;
        -mbl )
          mergeBatchLimit=$2
          shift
          ;;
        -ewt )
          waitTime=$2
          shift
          ;;
        -iwt )
          importWaitTime=$2
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
          propertiesFile=$2
          shift
          ;;
        --blog-id )
          # TODO: Need to remove below condition once all files are cleaned
          if [ ! -z $2 ]; then
            blogId=$2
            shift
          fi
          ;;
        --site-url )
          srcUrl=$2
          shift
          ;;
        --shib-url )
          srcShibUrl=$2
          shift
          ;;
        --g-analytics )
          srcGAnalytics=$2
          shift
          ;;
        --force )
          forceImport=--force
          ;;
        --drop-tables)
          dropTables=true
          ;;
        --drop-tables-sql)
          dropTableSql=true
          ;;
        --skip-export)
          skipExport=true
          ;;
        --skip-import)
          skipImport=true
          ;;
        --skip-network-import)
          skipNetworkImport=true
          ;;
        --skip-replace)
          skipReplace=true
          ;;
        --parallel-import)
          parallelImport=true
          ;;
        --is-last-import)
          isLastImport=true
          ;;
        --network-flag)
          networkFlag=true
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

  dbUser="${domain}_db_user"
  dbUser=${!dbUser}

  dbPassword="${domain}_db_pass"
  dbPassword=${!dbPassword}

  dbHostName="${domain}_db_host"
  dbHostName=${!dbHostName}

  dbSchema="${domain}_db_name"
  dbSchema=${!dbSchema}

  url="${domain}_url"
  url=${!url}

  hostName="${domain}_host"
  hostName=${!hostName}

  siteDir="${domain}_dir"
  siteDir=${!siteDir}

  remoteScriptDir="${domain}_remote_dir"
  remoteScriptDir=${!remoteScriptDir}

  DB_BACKUP_DIR="${domain}_db_backup_dir"
  DB_BACKUP_DIR=${!DB_BACKUP_DIR}

  shibUrl="${domain}_shib_url"
  shibUrl=${!shibUrl}

  shibLogoutUrl="${domain}_shib_logout_url"
  shibLogoutUrl=${!shibLogoutUrl}

  cdnUrl="${domain}_cdn_url"
  cdnUrl=${!cdnUrl}

  httpsCdnUrl="${domain}_https_cdn_url"
  httpsCdnUrl=${!httpsCdnUrl}

  gAnalytics="${domain}_g_analytics"
  gAnalytics=${!gAnalytics}

  # Set SSH Parameters
  sshKeyPath=$ssh_key_path
  sshUsername=$ssh_username

  if [ -z $remoteScriptDir ]; then
    remoteScriptDir='mirror_db'
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
  chmod 754 $dropSqlFile.sql
  
}

getDb() {
  local dbBackDir=$1
  if [ ! "$parallelImport" = true ]; then
	  rsync -avzhe ssh --include '*.sql' --exclude '*' --delete --progress ${sshUsername}@${hostName}:${dbBackDir}/ ${exportDir}/
  else
	  rsync -avzhe ssh --progress ${dbBackDir}/${DB_FILE_NAME} ${sshUsername}@${hostName}:${dbBackDir}/ ${exportDir}/
  fi
  #since db is copied to mirror_db server, setting value to exportDir
  readonly MIRROR_DB_BACKUP_DIR=$exportDir
}

putDb() {
  local dbBackDir=$1
  if [ ! "$parallelImport" = true ]; then
    echo "Database path on mirror_db: $dbBackDir"
	  rsync -avzhe ssh --include '*.sql' --exclude '*'  --delete --progress ${dbBackDir}/ ${sshUsername}@${hostName}:${remoteScriptDir}/${exportDir}/
  else
	  rsync -avzhe ssh --progress ${exportDir}/${DB_FILE_NAME} ${sshUsername}@${hostName}:${remoteScriptDir}/${exportDir}/
  fi
}

createRemoteScriptDir() {
  local location=$1
  echo "Creating ${remoteScriptDir} on ${location}..."
  ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "mkdir -p ${remoteScriptDir};"
}

uploadMirrorDbFiles() {
  local location=$1
  rsync -avzhe ssh --delete --progress ${structureFile} ${sshUsername}@${hostName}:${remoteScriptDir}/
  echo "Executing structure script for creating dir on ${location} server... "
  ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "cd ${remoteScriptDir}; ./${structureFile} mk ${exportDir}"
  if [ $location="$dest" ];then
    rsync -avzhe ssh --delete --progress ${utilityFile} ${exportScript} ${mergeScript} ${propertiesFile} ${importScript} ${superAdminTxt} ${sshUsername}@${hostName}:${remoteScriptDir}/
  else
    rsync -avzhe ssh --delete --progress ${utilityFile} ${exportScript} ${mergeScript} ${propertiesFile} ${sshUsername}@${hostName}:${remoteScriptDir}/
  fi
}

removeMirrorDbFiles() {
  local location=$1
  echo "Removing ${remoteScriptDir} from ${location}..."
  ssh -i ${sshKeyPath} ${sshUsername}@${hostName} "rm -rf ${remoteScriptDir};"
}
