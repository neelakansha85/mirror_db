#!/bin/bash

mirrorDbStructure() {
  # Config Options
  # do the following variables also have to be readonly
  local arg1=$1
  local exportDir=${2:-'db_export'}
  local importScript='import.sh'
  local dropSqlFile='drop_tables'
  local superAdminTxt='superadmin_dev.txt'
  local propertiesFile='db.properties'

  if [ "$arg1" == "mk" ]; then
	  if [ ! -d "$exportDir" ]; then
	    mkdir $exportDir
	  else
		  # Remove all .sql files from previous run if any
		  echo "Emptying ${exportDir} dir..."
		  rm -rf $exportDir
		  mkdir $exportDir
	  fi

	  # Remove all bash scripts from previous run if any
	  echo "Attempting to remove all old script files if exists on server"
	  rm -f $importScript $propertiesFile $dropSqlFile.sql $superAdminTxt

  elif [ "$arg1" == "rm" ]; then
	  rm -f $importScript $propertiesFile $dropSqlFile.sql $superAdminTxt
  fi
}

mirrorDbStructure $@
