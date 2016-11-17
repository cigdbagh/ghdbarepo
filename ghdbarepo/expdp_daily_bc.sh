#!/bin/sh
# Author   :  Ramesh Kalyandrug
# created  :  01/04/15
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
SCR_PATH="/db/sw/oracle/backup";export SCR_PATH
mv /backup/oracle/bcprod/daily/export.dir/bcadmin.dmp /backup/oracle/bcprod/daily/export.dir/old
#mv /backup/oracle/cmprod/daily/export.dir/cmadmin.dmp /backup/oracle/cmprod/daily/old/
sh $SCR_PATH/exp_database_full_bcprod_daily.sh
#sh $SCR_PATH/exp_database_full_cmprod_daily.sh
#gzip /backup/oracle/bcprod/export.dir/bcadmin.dmp
#gzip /backup/oracle/cmprod/export.dir/cmadmin.dmp
