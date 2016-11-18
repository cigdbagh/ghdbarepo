#!/bin/sh
# Author   :  Ramesh Kalyandrug
# Name     :  alert_tbs_sms.sh
# Desc     :  This script looks for negative number in  CURRENT_SEQUENCE_VALUES.TXT. It will create script to do alter sequences .
# created  :  09/22/09
# Modified :  xxxxxxxxx -- xxxxxxxxxxxxxxxxxxxxxxxxxxx
ERRMSG="Usage: `basename $0` <dbname> <schema1> "

if [ "$1" ]
   then DBNAME=$1
else echo $ERRMSG
     exit
fi
if [ "$2" ]
  then SCHEMA1=$2
else echo $ERRMSG
     exit 1
fi
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
ORACLE_SID=$DBNAME;export ORACLE_SID
ORACLE_TERM=vt100;export ORACLE_TERM
LOG_PATH="/tmp/logs";export LOG_PATH
#LOG_PATH="/tmp/rs";export LOG_PATH
TXT_FILE="${LOG_PATH}"/"test_tbs_alert.txt"
#SCR_PATH="/db/sw/oracle/backup/refresh_admin_tables"; export SCR_PATH
SCR_PATH="/db/sw/oracle/scripts/db_maint/db_monitor/usefull_sql"; export SCR_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getpopn1.sh`
###########################
sqlplus -S << END_SQL
${SCHEMA1}/${PWD}@${DBNAME}
set feed off;
set pagesize 100;
set wrap off;
set linesize 500;
set heading on;
set tab on;
set scan on;
set verify off;
column TBSP_NAME  format 9999999 heading "TBSP_NAME"
column TBSP_USEDSPS_GB  format 9999999 heading "TBSP_USEDSPS MB"
column TBSP_SIZE_GB format 9999999 heading "TBSP_SIZE MB"
column FREE_SPACE format 9999999 heading "FREE_SPACE MB"
column USED_PERCENT format 9999999 heading "USED_PERCENT"
spool $LOG_PATH/test_tbs_alert1.txt
SELECT TABLESPACE_NAME TBSP_NAME,
  USED_SPACE/128 TBSP_USEDSPS_gb,
  TABLESPACE_SIZE/128 TBSP_SIZE_GB,
 (TABLESPACE_SIZE-USED_SPACE)/128 FREE_SPAC,
  USED_PERCENT USED_PERCENT
 FROM SYS.DBA_TABLESPACE_USAGE_METRICS 
 where USED_PERCENT > 97
/
END_SQL
awk '/---/,printed==200 { ++printed; print; }' $LOG_PATH/test_tbs_alert1.txt > $LOG_PATH/test_tbs_alert2.txt
awk '{print $1" "$5}' $LOG_PATH/test_tbs_alert2.txt > $LOG_PATH/test_tbs_alert.txt
##echo "TBS alerts"|mail -a /tmp/rs/test_tbs_alert.txt -s "TBS used more than 95%.Verify /tmp/rs/test_tbs_alert.txt" 8316019864@vtext.com

if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
     echo "TBS alerts"| mail  -s "TBS used more than 97% in $DBNAME.Verify /tmp/logs/prod_tbs_alert.txt" 8316019864@vtext.com,8316014102@vtext.com,8312364743@vtext.com
      exit 1
   fi
fi
