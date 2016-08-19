#!/bin/bash

SRC=$1

. db.properties

if [ "$SRC" == 'prd' ]; then
  DB_USER=$prd_db_user
  DB_PASSWORD=$prd_db_pass
  DB_HOST_NAME=$prd_db_host
  DB_SCHEMA=$prd_db_name
  G_ANALYTICS=$prd_g_analytics
  URL=$prd_url
  SHIB_URL=$prd_shib_url

elif [ "$SRC" == 'nyudev' ]; then
  DB_USER=$dev_db_user
  DB_PASSWORD=$dev_db_pass
  DB_HOST_NAME=$dev_db_host
  DB_SCHEMA=$dev_db_name
  G_ANALYTICS=$dev_g_analytics
  URL=$dev_url
  SHIB_URL=$dev_shib_url

elif [ "$SRC" == 'nyuupdates' ]; then
  DB_USER=$nyuupdates_db_user
  DB_PASSWORD=$nyuupdates_db_pass
  DB_HOST_NAME=$nyuupdates_db_host
  DB_SCHEMA=$nyuupdates_db_name
  G_ANALYTICS=$nyuupdates_g_analytics
  URL=$nyuupdates_url
  SHIB_URL=$nyuupdates_shib_url

elif [ "$SRC" == 'sswtest' ]; then
  DB_USER=$sswtest_db_user
  DB_PASSWORD=$sswtest_db_pass
  DB_HOST_NAME=$sswtest_db_host
  DB_SCHEMA=$sswtest_db_name
  G_ANALYTICS=$sswtest_g_analytics
  URL=$sswtest_url
  SHIB_URL=$sswtest_shib_url

elif [ "$SRC" == 'wptst' ]; then
  DB_USER=$wptst_db_user
  DB_PASSWORD=$wptst_db_pass
  DB_HOST_NAME=$wptst_db_host
  DB_SCHEMA=$wptst_db_name
  G_ANALYTICS=$wptst_g_analytics
  URL=$wptst_url
  SHIB_URL=$wptst_shib_url

elif [ "$SRC" == 'pagely_prd' ]; then
  DB_USER=$pagely_prd_db_user
  DB_PASSWORD=$pagely_prd_db_pass
  DB_HOST_NAME=$pagely_prd_db_host
  DB_SCHEMA=$pagely_prd_db_name
  G_ANALYTICS=$pagely_prd_g_analytics
  URL=$pagely_prd_url # Value for URL replacement
  HOST_NAME=$pagely_prd_host
  DIR=$pagely_prd_dir
  SHIB_URL=$pagely_prd_shib_url

elif [ "$SRC" == 'pagely_test_prd' ]; then
  DB_USER=$pagely_test_prd_db_user
  DB_PASSWORD=$pagely_test_prd_db_pass
  DB_HOST_NAME=$pagely_test_prd_db_host
  DB_SCHEMA=$pagely_test_prd_db_name
  G_ANALYTICS=$pagely_test_prd_g_analytics
  URL=$pagely_test_prd_url # Value for URL replacement
  HOST_NAME=$pagely_test_prd_host
  DIR=$pagely_test_prd_dir
  SHIB_URL=$pagely_test_prd_shib_url
  SUPERADMIN=$pagely_test_prd_superadmin

elif [ "$SRC" == 'pagely_dev' ]; then
	DB_USER=$pagely_dev_db_user
	DB_PASSWORD=$pagely_dev_db_pass
	DB_HOST_NAME=$pagely_dev_db_host
  DB_SCHEMA=$pagely_dev_db_name
	URL=$pagely_dev_url # Value for URL replacement
  G_ANALYTICS=$pagely_dev_g_analytics
  HOST_NAME=$pagely_dev_host
  DIR=$pagely_dev_db_dir
  SHIB_URL=$pagely_dev_shib_url
  SUPERADMIN=$pagely_dev_superadmin
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
export G_ANALYTICS
export HOST_NAME
export DIR
export SHIB_URL
export SUPERADMIN

export SSH_KEY_PATH
export SSH_USERNAME

return