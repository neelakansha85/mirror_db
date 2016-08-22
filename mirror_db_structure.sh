#!/bin/bash

# Config Options
ARG1=$1
REMOTE_DIR=${2:-'mirror_db'}
BACKUP_DIR=${3:-'db_backup'}

# Move mysql.sql to archives with current date
if [ "$ARG1" == "mk" ]; then
	
	if [ ! -d "$REMOTE_DIR" ]; then
	  mkdir $REMOTE_DIR
	fi

	if [ ! -d "$BACKUP_DIR" ]; then
	  cd $REMOTE_DIR
	  mkdir $BACKUP_DIR
	fi

	# Remove all bash scripts from previous run if any
	echo "Attempting to remove all bash files if exists in ${REMOTE_DIR}"
	rm *.sh

	#chmod 775 $REMOTE_DIR $REMOTE_DIR/$BACKUP_DIR

elif [ "$ARG1" == "rm" ]; then
	cd $REMOTE_DIR
	rm *.sh
	rm *.properties
	rm drop_tables.sql
fi

