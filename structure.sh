#!/bin/bash

# Config Options
ARG1=$1
REMOTE_DIR=${2:-'mirror_db'}
ARCHIVES_DIR=${3:-'archives'}

# Move mysql.sql to archives with current date
if [ "$ARG1" == "mk" ]; then
	
	if [ ! -d "$REMOTE_DIR" ]; then
	  mkdir $REMOTE_DIR
	fi

	if [ ! -d "$ARCHIVES_DIR" ]; then
	  cd $REMOTE_DIR
	  mkdir $ARCHIVES_DIR
	fi

	#chmod 775 $REMOTE_DIR $REMOTE_DIR/$ARCHIVES_DIR

elif [ "$ARG1" == "rm" ]; then
	cd $REMOTE_DIR
	rm *.sh
	rm *.properties
	rm drop_tables.sql
fi

