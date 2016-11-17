#!/bin/sh
# Name     : alert.sh
# Author   : Ramesh Kalyandrug 
# created  : 09/25/13 
# Modified :  
####################################             

ORACLE_SID=prod;export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
DBNAME=$ORACLE_SID
SCR_PATH="/u01/app/oracle/product/12.1.0.2/db_1/db_1/rdbms/admin";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/db_maint/db_monitor/logs";export LOG_PATH
#LOG_PATH="/tmp";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

LOG_FILE="${LOG_PATH}/alert_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}/alert_${DBNAME}.txt"
SCHEMA="sys"
#PWD=`sh ${PWD_PATH}/getdopn1.sh`
PWD=`sh ${PWD_PATH}/getdopnsys1.sh`

MAIL_LOG_TO_DBA="rkalyandrug@ciginsurance.com rpaul@ciginsurance.com"
##*##MAIL_LOG_TO_USER="rpaul@ciginsurance.com"
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="DBA - Production Alert Log Check : Error in  alert log  in ${U_S_HOST}"
MAIL_LOG_SUB2="DBA - Production Alert Log Check : Alert_prod.sh completed in ${U_S_HOST}"
MAIL_LOG_SUB3="DBA - Production Alert Log Check : Please verify oracle alert log  in ${U_S_HOST}"

sqlplus -S /nolog << END_SQL
connect ${SCHEMA}/${PWD}@${DBNAME} as sysdba

set pagesize 1500 linesize 100;
set heading on ;
spool ${LOG_FILE}
prompt
prompt Errors in Alert log file in ${DBNAME} ...
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
prompt
show user;
select name database from v\$pdbs;
--select name instance_name from cig_instance;

SELECT  ROWNUM LineNumber,originating_timestamp TimeStamp, message_text Error
FROM X\$DBGALERTEXT
WHERE originating_timestamp > (SYSDATE - 30/1440) AND message_text LIKE ('%ORA-%') 
--or  message_text LIKE  ('%TNS%')
ORDER BY originating_timestamp;
spool off;
END_SQL

##### Error Handling #######

pg ${LOG_FILE} |grep ORA- > ${TXT_FILE}
##pg ${LOGFILE1}|egrep -vi 'ORA-00000|ORA-00000' > ${TXTFILE1}

CURR_DATE=`date "+%c"`
###*###ORATAB=/etc/oratab
echo "`date`   "

if [ -f ${TXT_FILE} ]; then
       ERR_NO=`cat ${TXT_FILE} | grep 2396`
       if ERR_NO=2396 ; then
	exit
       else 
	mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
       fi
fi
