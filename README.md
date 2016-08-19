# Mirror DB
This is a script used to download or get an export of your database (**Recommended for Large Databases** though works for small ones too) using mysqldump command line. You can run this script on server or remotely from a machine which has direct access to the database server.

Please note this is not the most efficient way of getting a database export since there are tons of other ways to do so, however this method is for a special use case where you do not have SSH access to your server.

## How it works
* Request your hosting provider to whitelist your static IP to access your database server directly.
* Open Terminal run `git clone git@github.com:neelakansha85/remote_db_export.git`
* Create a `db.preperties` file using `sample_db.properties` with your server specific information
* Execute remote_db_export.sh in terminal with src other optional arguments. `./remote_db_export.sh prd remote`
* It will create a list of all tables from the db server with the given database name and store it in `db_backup/table_list.txt`.
* It then uses mysqldump to individually export each table from the `table_list.txt` in .gz format from the server.
* Executes ./merge.sh at after exporting to merge them all to single mysql.sql file. 

I will be working on another script soon to import this db to another server soon.

If you have below conditions I would recommend using this script:
* Do not have SSH access to server
* Have large database with many tables
* phpMyAdmin is way too slow to work with
* You can request your hosting provider to allow your static IP to be whitelisted for accessing DB server
* DB backups provided by hosting provider are not reliable/correct.
* You would like to periodically get DB backup (for various reasons such as backup storage, mirroring production to dev env, etc)
* You the least amount of impact to your system during the DB export process
* You need to automate this process

I have been running this for our Wordpress system hosted at WPEngine which has 1GB to database with approx 68,000 tables in it.
Please note: Reuqest your hosting provider to update mysql open file limit to value greater than the number of tables you have in database in order to avoid database server from crashing. 

Please also test this on your local/dev environment before running on production to avoid any unwanted issues.

Hope this helps you. Please give feedback if you have any. 

