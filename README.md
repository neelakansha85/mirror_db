# Mirror DB
![Mirror DB Banner](assets/mirror-db-banner.jpg?raw=true "Mirror DB")

This is a script used to download or get an export of your database (Recommended for Large Databases though works for small ones too) using mysqldump command line and import it to another database server. You can run this script on the server or remotely from a machine which has it's IP whitelisted to access database server.

Please note this is not the most efficient way of getting a database export since there are tons of other ways to do so, however this method is for a special use case where you do not have SSH access to your source server. 

## How it works
* Request your hosting provider to whitelist your static IP to access your database server directly.
* Open Terminal run `git clone git@github.com:neelakansha85/mirror_db.git`
* Create a `db.preperties` file using `sample_db.properties` with your server specific information
* Execute mirror_db.sh in terminal with src dest and other optional arguments. `./mirror_db.sh -s prd -d dev` or `nohup ./mirror_db.sh -s prd -d dev > mirror_db.log &`
    * Recommended for Production migration -
`nohup ./mirror_db.sh -s prd -d new_prd -mbl 5000 --drop-tables > mirror_db.log &`
* It will create a list of all tables from the db server with the given database name and store it in `db_backup/table_list.txt`.
* It then uses mysqldump to individually export each table from the `table_list.txt` in .gz format from the server.
* Executes ./merge.sh at after exporting to merge them all to single mysql.sql file. 

### Options Available
* -s - source for exporting database
* -d - destination for importing database
* -ebl - export batch limit is used to allow exporting tables in groups/batches with given wait time between new batch (default: 10)
* -mbl - merge batch limit is used to split large database into several parts with each part consisting of no of tables specified with -mbl (default: 10000)
* -ewt - export wait time to be used between each new batch of tables being exported using mysqldump (default: 3 seconds)
* -iwt - import wait time to be used between each mysql import command execution (default: 180 seconods)
* -lf - specify file name which stores a list of all tables in database (default: table_list.txt)
* -dbf - specify file name for the final merged database (default: mysql_[current-date].sql)
* --site-url - source site url for search and replace
* --shib-url - source shibboleth login url for search and replace
* --g-analytics - source google analytics code for search and replace
* --force - add --force flag for mysql import process to continue importing while error occurs
* --drop-tables - drop tables using wp-cli (recommended and fast)
* --drop-tables-sql - drop tables using sql procedure
* --skip-export - skip execution of exporting remote database
* --skip-import - skip execution of mysql command which imports database (it will perform search and replace and uploading of sql files though)
* --parallel-import - execute export and import process in parallel batches, once a batch of x (default 7000) tables is downloaded, it will merge them and start the process of uploading it to the destination server in a separate process independent from export process. 
  * The advantage of this flag is that it always exports and imports the network tables for a wordpress multisite before any other tables. This makes the system available for use once network tables are imported with minimal downtime and then continues to export and import remaining site tables. This can be a very useful during production database migration to achieve minimal downtime and make necessary changes to system while it is still being imported.


If you have below conditions I would recommend using this script:
* Do not have SSH access to source server
* Have large database with many tables
* phpMyAdmin is way too slow to work with
* You can request your hosting provider to allow your static IP to be whitelisted for accessing DB server
* DB backups provided by hosting provider are not reliable/correct.
* You would like to periodically get DB backup (for various reasons such as backup storage, mirroring production to dev env, etc)
* You want the least amount of impact to your system during the DB export process
* You need to automate this process

I have been running this for our Wordpress system hosted at WPEngine which has 1.4GB to database with approx 90,000 tables in it.
Please note: Reuqest your hosting provider to update mysql open file limit to value greater than the number of tables you have in database in order to avoid database server from crashing. 

Please also test this on your local/dev environment before running on production to avoid any unwanted issues.

Hope this helps you. Please give feedback if you have any. 
