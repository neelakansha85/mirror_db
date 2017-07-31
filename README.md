# Mirror DB
![Mirror DB Banner](assets/mirror-db-banner.jpg?raw=true "Mirror DB")

This is a script used to download or get an export of your database (Recommended for Large Databases though works for small ones too) using mysqldump command line and import it to another database server. You can run this script on the server or remotely from a machine which has it's IP whitelisted to access database server.

Please note this is not the most efficient way of getting a database export since there are tons of other ways to do so, however this method is for a special use case where you do not have SSH access to your source server. 

## How it works
* Request your hosting provider to whitelist your static IP to access your database server directly.
* Open Terminal run `git clone git@github.com:neelakansha85/mirror_db.git`
* Create a `db.properties` file using `sample_db.properties` with your server specific information
* Execute mirror_db.sh in terminal with src dest and other optional arguments. `./mirror_db.sh -s prd -d dev` or `nohup ./mirror_db.sh -s prd -d dev > mirror_db.log &`
    * Recommended for Production migration -
`nohup ./mirror_db.sh -s prd -d new_prd -mbl 5000 --drop-tables > mirror_db.log &`
* It will create a list of all tables from the db server with the given database name and store it in `db_backup/table_list.txt`.
* It then uses mysqldump to individually export each table from the `table_list.txt` in .gz format from the server.
* Executes ./merge.sh at after exporting to merge them all to single mysql.sql file. 

### Options Available
* -s | --source > source environment for exporting database eg. dev, qa, prd
* -d | --destination > destination environment for importing database eg. dev, qa, prd
* --db-backup > Used to specify directory path to import the sql files from mirror_db server. Must have --skip-export flag set.
* -ebl > export batch limit is used to allow exporting tables in groups/batches with given wait time between new batch (default: 10)
* -pl > defines pool limit to complete exporting given number of tables (default: 300)
* -mbl > merge batch limit is used to split large database into several parts with each part consisting of no of tables specified with -mbl (default: 10000)
* -ewt > export wait time to be used between each new batch of tables being exported using mysqldump (default: 3 seconds)
* -iwt > import wait time to be used between each mysql import command execution (default: 180 seconods)
* -lf > specify file name which stores a list of all tables in database (default: table_list.txt)
* -dbf > specify file name for the final merged database (default: SRC_[current-date-time].sql)
* -pf | --properties-file > specify File Path to db.properties file
* --blog-id > export and import tables of the specified blogId only 
* --site-url > source site url for search and replace
* --shib-url > source shibboleth login url for search and replace
* --g-analytics > source google analytics code for search and replace
* --force > add --force flag for mysql import process to continue importing while error occurs
* --drop-tables - drop tables using wp-cli (recommended and fast)
* --drop-tables-sql - drop tables using sql procedure
* --skip-export - skip execution of exporting remote database
* --skip-import - skip execution of mysql command which imports database (it will perform search and replace and uploading of sql files though)
* --skip-network-import > skip execution of mysql command which imports Network Tables
* --skip-replace > skips the replacement of source url, shib url and Google Analytics.
* --parallel-import > execute export and import process in parallel batches, once a batch of x (default 7000) tables is downloaded, it will merge them and start the process of uploading it to the destination server in a separate process independent from export process. 
  * The advantage of this flag is that it always exports and imports the network tables for a wordpress multisite before any other tables. This makes the system available for use once network tables are imported with minimal downtime and then continues to export and import remaining site tables. This can be a very useful during production database migration to achieve minimal downtime and make necessary changes to system while it is still being imported.
* --is-last-import > used only during import process to take note whether it is the last SQL import.
* --network-flag > export and import all network tables only

### Workflow: 

Following scripts include the **_ utilityFunctions.sh _** script to handle arguments and configuration information

1. mirror_db.sh
	* Minimum Requirements: (-s) Source and (-d) Destination flags to run on specific environments
	* Runs upload_export.sh for database export process. 
	* Runs upload_import.sh for database import process.
	
2. upload_export.sh
	* It creates the directory structure for the source environment.
	* Based on the command-line input flags this script looks for --skip-export flag and runs the export.sh script on the source environment.
	* Calls getDb() to transfer the sql files from source environment to mirror_db server.
	* Cleans source by deleting the structure after the merged sql files have been transferred to mirror_db server.
	
3. export.sh
	* Accepts -pl, -mbl flags etc and runs the mysql export process.
	* This script opens mysql connection to dump the sql tables from source and runs the merge script.
	* Creates list of network and non-network tables exported.

4. merge.sh
	* This script merges individual sql files into consolidated files based on network tables, non-network tables and blogId specific tables.
	* Removes previous folder to clean sql files if present
	* Archives the SQL file
	
5. upload_import.sh
	* It creates the directory structure for the destination environment.
	* Calls putDb() to transfer the sql files from mirror_db server to destination environment.
	* Based on the command-line input flags this script looks for --skip-import flag and runs the import.sh script on the destination environment.
	* Cleans destination by deleting the structure after the import process is completed.

6. import.sh
	* Optionally accepts directory path for the sql files to be imported.
	* Imports the data from the SQL files.
	* Performs search&replace on the SQL files to change the domain and environment information within the SQL files.
	* performs afterImport to create serialized array for superadmin users from the superadmin_dev.txt list and updates in the Wordpress table.

7. utilityFunctions.sh
   * Consists of utility functions used throughout the mirroring process on any server
   

####Utility Functions
1. getDb() : Transfers the merged sql files from source to the mirror_db server.
2. putDb() : Transfers files from mirror_db server to destination environment.
3. createRemoteScriptDir() : Creates directory on server SRC/DEST.
4. prepareForDist() : Creates a dist folder consisting of all required scripts and sets permissions for running the scripts.
5. uploadMirrorDbFiles() : Uploads entire dist folder to the server.
6. removeMirrorDbFiles() : Cleans the folder structure for unwanted scripts.
7. getWorkspace() : Gets back value of the present working directory pwd.
8. setGlobalVariables() : Sets values for readonly constants.
9. setExportGlobalVariables() : Sets values for readonly constants to be used by export.sh and merge.sh
10. parseArgs(), exportParseArgs(), importParseArgs() : For parsing incoming flags on OPS, SRC and DEST respectively.
11. readProperties() : Stores server related information into constants needed to access the server databases.

#### Logic Operation handled within the package
#### Normal Operation.
1. Clean Directory Structure at Source
2. Complete Export Process
3. Clean Directory Structure at Destination
4. Complete Import Process
5. Complete Adding Super Admins

#### Parallel Operation. [Past Logic]
1. Clean Directory Structure at Source
2. Export first batch and transfer it to mirror_db server for import process
3. Continue exporting rest of the batches and continue importing previous batch
4. Last batch if left will require one spawn of import process.

##### Directory Structure on mirror_db
##### Refer Workflow for script functionality.
    .
    ├── ...
    ├── mirror_db               # Folder - All the scripts and configuration files are placed here for file transfer
    │   └── db_export           # Folder - Merged SQL files are place here from source
    │   └── dist                # Folder - all scripts and files needed to be uploaded to respective servers
    │   └── upload_export.sh    
    │   └── upload_import.sh         
    │   └── export.sh
    │   └── import.sh 
    │   └── merge.sh
    │   └── utilityFunctions.sh
    │   └── drob_tables.sql
    │   └── superadmin_dev.txt
    │   └── db.properties       #  Configuration file
    └── ...
        
##### Directory Structure on Source
###### table_list.txt contains list of WordPress tables and is used to get intermediate table_lists
###### eg. table_list_network.txt | table_list_non_network.txt | table_list_blog_blogId.txt
    .
    ├── ...
    ├── mirror_db               
    │   └── db_export             
    │       └── table_list.txt    # Contains wordpress tables list for the SOURCE SCHEMA 
    │       └── db_merged                        # Merged SQL files placed here for transfer to mirror_db
    │               └── SRC_%Y-%m-%d_%H%M%S.sql  # Naming Convention for SQL files for each table
    │               └── SRC_%Y-%m-%d_%H%M%S_network.sql
    │               └── SRC_%Y-%m-%d_%H%M%S_blog_blogId.sql
    │   └── utilityFunctions.sh 
    │   └── export.sh
    │   └── merge.sh
    │   └── import.sh
    │   └── db.properties
    │   └── superadmin_dev.txt
    ├── db_backup                # Archive folder at Source to store all the merged SQL files
    │       └── SRC_%Y-%m-%d_%H%M%S    # Archive folder to store merged files based on timestamp
    └── ...

##### Directory Structure on Destination

    .
    ├── ...
    ├── mirror_db               # Parent Folder
    │   ├── db_export           
    │   ├── export.sh
    │   ├── import.sh 
    │   ├── merge.sh
    │   ├── utilityFunctions.sh
    │   ├── db.properties
    │   ├── superadmin_dev.txt  #list of super admin users for destination
    │   └── drob_tables.sql
    └── ...



###### If you have below conditions I would recommend using this script:
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
    