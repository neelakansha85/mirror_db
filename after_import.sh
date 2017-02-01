#!/bin/bash

. parse_arguments.sh
if [[ ! $? == 0 ]]; then
    echo "Parsing arguments failed!"
    exit 1
fi

# Import instance based environment variables
. read_properties.sh $DEST
if [[ ! $? == 0 ]]; then
    echo "Read properties script failed!"
    exit 1
fi

SUPER_ADMIN_TXT="`cat superadmin_dev.txt`"
SUPER_ADMIN=`php -r "print_r(serialize(array(${SUPER_ADMIN_TXT})));"`

# Setting pwd to wordpress installation dir
cd ~/${SITE_DIR}

# Replacing super admins list with the dev list
wp db query "UPDATE wp_sitemeta SET meta_value='${SUPER_ADMIN}' WHERE meta_key='site_admins';";

