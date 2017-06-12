#!/bin/bash

DOMAIN_ARG=$1

. db.properties

if [ "$DOMAIN_ARG" == 'prd' ]; then
  DB_USER=$prd_db_user
  DB_PASSWORD=$prd_db_pass
  DB_HOST_NAME=$prd_db_host
  DB_SCHEMA=$prd_db_name
  URL=$prd_url
  HOST_NAME=$prd_host
  SITE_DIR=$prd_dir
  REMOTE_SCRIPT_DIR=$prd_remote_dir
  DB_BACKUP_DIR=$prd_db_backup_dir
  SHIB_URL=$prd_shib_url
  SHIB_LOGOUT_URL=$prd_shib_logout_url
  CDN_URL=$prd_cdn_url
  HTTPS_CDN_URL=$prd_https_cdn_url
  G_ANALYTICS=$prd_g_analytics

elif [ "$DOMAIN_ARG" == 'tstprd' ]; then
  DB_USER=$tstprd_db_user
  DB_PASSWORD=$tstprd_db_pass
  DB_HOST_NAME=$tstprd_db_host
  DB_SCHEMA=$tstprd_db_name
  URL=$tstprd_url
  HOST_NAME=$tstprd_host
  SITE_DIR=$tstprd_dir
  REMOTE_SCRIPT_DIR=$tstprd_remote_dir
  DB_BACKUP_DIR=$tstprd_db_backup_dir
  SHIB_URL=$tstprd_shib_url
  SHIB_LOGOUT_URL=$tstprd_shib_logout_url
  CDN_URL=$tstprd_cdn_url
  HTTPS_CDN_URL=$tstprd_https_cdn_url
  G_ANALYTICS=$tstprd_g_analytics

elif [ "$DOMAIN_ARG" == 'dev' ]; then
  DB_USER=$dev_db_user
  DB_PASSWORD=$dev_db_pass
  DB_HOST_NAME=$dev_db_host
  DB_SCHEMA=$dev_db_name
  URL=$dev_url
  HOST_NAME=$dev_host
  SITE_DIR=$dev_dir
  REMOTE_SCRIPT_DIR=$dev_remote_dir
  DB_BACKUP_DIR=$dev_db_backup_dir
  SHIB_URL=$dev_shib_url
  SHIB_LOGOUT_URL=$dev_shib_logout_url
  CDN_URL=$dev_cdn_url
  HTTPS_CDN_URL=$dev_https_cdn_url
  G_ANALYTICS=$dev_g_analytics
  SUPERADMIN=$dev_superadmin

elif [ "$DOMAIN_ARG" == 'dev2' ]; then
  DB_USER=$dev2_db_user
  DB_PASSWORD=$dev2_db_pass
  DB_HOST_NAME=$dev2_db_host
  DB_SCHEMA=$dev2_db_name
  URL=$dev2_url
  HOST_NAME=$dev2_host
  SITE_DIR=$dev2_dir
  REMOTE_SCRIPT_DIR=$dev2_remote_dir
  DB_BACKUP_DIR=$dev2_db_backup_dir
  SHIB_URL=$dev2_shib_url
  SHIB_LOGOUT_URL=$dev2_shib_logout_url
  CDN_URL=$dev2_cdn_url
  HTTPS_CDN_URL=$dev2_https_cdn_url
  G_ANALYTICS=$dev2_g_analytics
  SUPERADMIN=$dev2_superadmin

elif [ "$DOMAIN_ARG" == 'qa' ]; then
  DB_USER=$qa_db_user
  DB_PASSWORD=$qa_db_pass
  DB_HOST_NAME=$qa_db_host
  DB_SCHEMA=$qa_db_name
  URL=$qa_url
  HOST_NAME=$qa_host
  SITE_DIR=$qa_dir
  REMOTE_SCRIPT_DIR=$qa_remote_dir
  DB_BACKUP_DIR=$qa_db_backup_dir
  SHIB_URL=$qa_shib_url
  SHIB_LOGOUT_URL=$qa_shib_logout_url
  CDN_URL=$qa_cdn_url
  HTTPS_CDN_URL=$qa_https_cdn_url
  G_ANALYTICS=$qa_g_analytics
  SUPERADMIN=$qa_superadmin

elif [ "$DOMAIN_ARG" == 'qa2' ]; then
  DB_USER=$qa2_db_user
  DB_PASSWORD=$qa2_db_pass
  DB_HOST_NAME=$qa2_db_host
  DB_SCHEMA=$qa2_db_name
  URL=$qa2_url
  HOST_NAME=$qa2_host
  SITE_DIR=$qa2_dir
  REMOTE_SCRIPT_DIR=$qa2_remote_dir
  DB_BACKUP_DIR=$qa2_db_backup_dir
  SHIB_URL=$qa2_shib_url
  SHIB_LOGOUT_URL=$qa2_shib_logout_url
  CDN_URL=$qa2_cdn_url
  HTTPS_CDN_URL=$qa2_https_cdn_url
  G_ANALYTICS=$qa2_g_analytics
  SUPERADMIN=$qa2_superadmin

else
  echo "DOMAIN_ARG incorrectly specified"
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
export DB_BACKUP_DIR
export SHIB_URL
export SHIB_LOGOUT_URL
export G_ANALYTICS
export SUPERADMIN

export SSH_KEY_PATH
export SSH_USERNAME

return