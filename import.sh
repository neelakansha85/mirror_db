#!/bin/bash

. utilityFunctions.sh

replaceShibUrl() {
  local dbFile="$1"
  # Replace Shib Production with Shib QA
  echo "Replacing Shibboleth URL..."
  sed -i'' "s@${srcShibUrl}@${destShibUrl}@g" $dbFile
  sed -i'' "s@${srcShibLogoutUrl}@${destShibLogoutUrl}@g" $dbFile
}

replaceDomain() {
  local dbFile="$1"
  # Replace old domain with the new domain
  echo "Replacing Site URL..."
  echo "Running -> sed -i'' \"s@${srcUrl}@${destUrl}@g\" ${MRDB}"
  sed -i'' "s@${srcUrl}@${destUrl}@g" $dbFile
  echo "Running -> sed -i'' \"s@${srcUrl2}@${destUrl2}@g\" ${MRDB}"
  sed -i'' "s@${srcUrl2}@${destUrl2}@g" $dbFile
  echo "Running -> sed -i'' \"s@${srcUrl3}@${destUrl3}@g\" ${MRDB}"
  sed -i'' "s@${srcUrl3}@${destUrl3}@g" $dbFile
}

replaceCdnUrl() {
  local dbFile="$1"
  echo "Replacing CDN URL..."
  sed -i'' "s@${srcCdnUrl}@${destCdnUrl}@g" $dbFile
  sed -i'' "s@${srcHttpsCdnUrl}@${destHttpsCdnUrl}@g" $dbFile
}

replaceGoogleAnalytics() {
  local dbFile="$1"
  echo "Replacing Google Analytics code..."
  sed -i'' "s@${srcGoogleAnalytics}@${destGoogleAnalytics}@g" $dbFile
}

searchReplace() {
  readProperties $src
  local srcUrl=",'${URL}"
  local srcUrl2=",'http://${URL}"
  local srcUrl3=",'https://${URL}"
  local srcShibUrl=",'${SHIB_URL}'"
  local srcShibLogoutUrl=",'${SHIB_LOGOUT_URL}'"
  local srcGoogleAnalytics="${G_ANALYTICS}"
  local srcCdnUrl="${CDN_URL}"
  local srcHttpsCdnUrl="${HTTPS_CDN_URL}"

  readProperties $dest
  local destUrl=",'${URL}"
  local destUrl2=",'http://${URL}"
  local destUrl3=",'https://${URL}"
  local destShibUrl=",'${SHIB_URL}'"
  local destShibLogoutUrl=",'${SHIB_LOGOUT_URL}'"
  local destGoogleAnalytics="${G_ANALYTICS}"
  local destCdnUrl="${CDN_URL}"
  local destHttpsCdnUrl="${HTTPS_CDN_URL}"

  cd ${exportDir}

  if [ ! "$skipReplace" = true ]; then
    for MRDB in $(ls *.sql)
    do
      if [ -e ${MRDB} ]; then
        echo "File ${MRDB} found..."
        echo "Changing environment specific information"
        
        if [ ! -z ${srcShibUrl} ] && [ "${srcShibUrl}" != "''" ]; then
          replaceShibUrl "$MRDB"
        fi

        if [ ! -z ${srcUrl} ]; then
          replaceDomain "$MRDB"
        fi

        if [ ! -z ${srcGoogleAnalytics} ] && [ "${srcGoogleAnalytics}" != "''" ]; then
          replaceGoogleAnalytics "$MRDB"
        fi

        if [ ! -z ${srcCdnUrl} ] && [ "${srcCdnUrl}" != "''" ] && [ ! -z ${srcHttpsCdnUrl} ] && [ "${srcHttpsCdnUrl}" != "''" ] ; then
          replaceCdnUrl "$MRDB"
        fi
      fi
    done
  fi

  # Get to root dir
  cd ..
}

importTables() {
  echo "Disabling foreign key check before importing db"
	mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} ${dbSchema} -e "SET foreign_key_checks=0"
  # SQL files are inside $exportDir
  cd ${exportDir}

	if [ ! -z $DB_FILE_NAME ]; then
	  # Import statement
		echo "Starting to import ${DB_FILE_NAME}"
		mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} ${dbSchema} ${forceImport} < ${DB_FILE_NAME}
		# Remove file to avoid importing it twice
		rm $DB_FILE_NAME
	else
		# Scan for all *.sql files to import
		for MRDB in $(ls *.sql)
		do
			# Import statement
			echo "Starting to import ${MRDB}"
			mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} ${dbSchema} ${forceImport} < ${MRDB}
			sleep $importWaitTime
		done
	fi
	# Get to root dir
  cd ..

	echo "Enabling foreign key check after importing db"
	mysql --host=${dbHostName} --user=${dbUser} --password=${dbPassword} ${dbSchema} -e "SET foreign_key_checks=1"
}

afterImport() {
  local superAdminTxt="$(cat superadmin_dev.txt)"
  local superAdmin=$(php -r "print_r(serialize(array(${superAdminTxt})));")

  # Setting pwd to wordpress installation dir
  cd ~/${siteDir}

  # Replacing super admins list with the dev list
  wp db query "UPDATE wp_sitemeta SET meta_value='${superAdmin}' WHERE meta_key='site_admins';";
}

importMain() {
  local exportDir='db_export'
  local dropSqlFile='drop_tables'

  parseArgs $@
  searchReplace

  if [ ! "$skipImport" = true ]; then
    importTables
  fi

  afterImport
}

importMain $@