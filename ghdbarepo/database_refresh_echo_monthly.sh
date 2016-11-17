#!/bin/sh
#!/bin/sh
# Author   :  Sasi Sivadasan 
# created  :  07/18/01
# Modified :  06/27/05 - Sasi Sivadasan -Path of scripts and logs changed to /database_refresh and /database_refresh/logs for common scripts

DBNAME="prod_rac";export DBNAME
ORACLE_HOME=/u01/app/oracle/product/12.1.0/db_1;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
SCRIPT_PATH="/db/sw/oracle/scripts/database_refresh/monthly";export SCRIPT_PATH
COMM_PATH="/db/sw/oracle/scripts/database_refresh";export COMM_PATH
LOG_PATH="/db/sw/oracle/scripts/database_refresh/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/database_refresh/oldlogs";export OLDLOG_PATH
#DATA_PATH_CIG="/data/a27/oracle/db_prod/datapump/cigadmin/export.dir";export DATA_PATH_CIG
DATA_PATH_CIG="/backup/oracle/a27/cigadmin/export.dir";export DATA_PATH_CIG
DATA_PATH_WH="/backup/oracle/a28/whouse/export.dir";export DATA_PATH_WH
MV="/bin/mv"
RM="/bin/rm"

$MV ${LOG_PATH}/*.dat ${OLDLOG_PATH}/
$MV ${LOG_PATH}/*.lst ${OLDLOG_PATH}/
$MV ${LOG_PATH}/*.log ${OLDLOG_PATH}/
$MV ${LOG_PATH}/*.txt ${OLDLOG_PATH}/
$MV ${LOG_PATH}/*.err ${OLDLOG_PATH}/
$RM ${DATA_PATH_CIG}/*.dmp
$RM ${DATA_PATH_WH}/*.dmp

### This script added to take the export of WHOUSE and CIGADMIN tables before data refresh.
### Also data refresh order changes to start with CIGADMIN

sh $SCRIPT_PATH/expdp_all_before_refresh.sh
#sh $COMM_PATH/ftp_database_refresh_main.sh
