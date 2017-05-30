#!/bin/bash

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
