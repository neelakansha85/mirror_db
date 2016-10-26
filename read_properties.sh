#!/bin/bash

SRC=$1

. db.properties

if [ "$SRC" == 'prd' ]; then
  DB_USER=$prd_db_user
  DB_PASSWORD=$prd_db_pass
  DB_HOST_NAME=$prd_db_host
  DB_SCHEMA=$prd_db_name
  URL=$prd_url
  HOST_NAME=$prd_host
  SITE_DIR=$prd_dir
  REMOTE_SCRIPT_DIR=$prd_remote_dir
  SHIB_URL=$prd_shib_url
  SHIB_LOGOUT_URL=$prd_shib_logout_url
  G_ANALYTICS=$prd_g_analytics

elif [ "$SRC" == 'dev' ]; then
  DB_USER=$dev_db_user
  DB_PASSWORD=$dev_db_pass
  DB_HOST_NAME=$dev_db_host
  DB_SCHEMA=$dev_db_name
  URL=$dev_url
  HOST_NAME=$dev_host
  SITE_DIR=$dev_db_dir
  REMOTE_SCRIPT_DIR=$dev_remote_dir
  SHIB_URL=$dev_shib_url
  SHIB_LOGOUT_URL=$dev_shib_logout_url
  G_ANALYTICS=$dev_g_analytics
  SUPERADMIN=$dev_superadmin

elif [ "$SRC" == 'dev2' ]; then
  DB_USER=$dev2_db_user
  DB_PASSWORD=$dev2_db_pass
  DB_HOST_NAME=$dev2_db_host
  DB_SCHEMA=$dev2_db_name
  URL=$dev2_url
  HOST_NAME=$dev2_host
  SITE_DIR=$dev2_db_dir
  REMOTE_SCRIPT_DIR=$dev2_remote_dir
  SHIB_URL=$dev2_shib_url
  SHIB_LOGOUT_URL=$dev2_shib_logout_url
  G_ANALYTICS=$dev2_g_analytics
  SUPERADMIN=$dev2_superadmin

elif [ "$SRC" == 'qa' ]; then
  DB_USER=$qa_db_user
  DB_PASSWORD=$qa_db_pass
  DB_HOST_NAME=$qa_db_host
  DB_SCHEMA=$qa_db_name
  URL=$qa_url
  HOST_NAME=$qa_host
  SITE_DIR=$qa_db_dir
  REMOTE_SCRIPT_DIR=$qa_remote_dir
  SHIB_URL=$qa_shib_url
  SHIB_LOGOUT_URL=$qa_shib_logout_url
  G_ANALYTICS=$qa_g_analytics
  SUPERADMIN=$qa_superadmin

else
  echo "Source incorrectly specified"
  exit 1;
fi

# Set SSH Parameters
SSH_KEY_PATH=$ssh_key_path
SSH_USERNAME=$ssh_username

export DB_USER
export DB_PASSWORD
export DB_HOST_NAME
export DB_SCHEMA
export URL
export HOST_NAME
export SITE_DIR
export REMOTE_SCRIPT_DIR
export SHIB_URL
export SHIB_LOGOUT_URL
export G_ANALYTICS
export SUPERADMIN

export SSH_KEY_PATH
export SSH_USERNAME

return