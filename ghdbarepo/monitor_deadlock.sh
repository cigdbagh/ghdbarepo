#!/bin/sh
# Name     : monitor_deadlock.sh
# created  : 12/14/2005
# Modified :
# Desc     : Shell script to monitor deadlocks in a database.
# Features include - log file which will be e-mailed to the DBA Team
#                  - Common file referenced for MAIL_LOG_TO_DBA
#          03/06/2006 - mailx commented out when lock is not detected.

ERRMSG="Usage: `basename $0` <dbname>"
if [ "$1" ]
   then DBNAME=$1
else echo ${ERRMSG}
   exit
fi 

ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

SCRIPT_PATH="/db/sw/oracle/scripts/db_maint/monitor_locks";export SCRIPT_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/db_maint/monitor_locks/oldlogs";export OLDLOG_PATH
LOG_PATH="/db/sw/oracle/scripts/db_maint/monitor_locks/logs";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`

U_DBNAME=`echo $DBNAME | tr "[a-z]" "[A-Z]"`
MV="/bin/mv"
CURR_DATE=`date "+%x %X"`

S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`

MAIL_LOG_SUB_DETECT="Daily Scripts (${U_S_HOST}): ATTN - DEADLOCK detected in ${U_DBNAME} at ${CURR_DATE}"
MAIL_LOG_SUB_NO_DETECT="Daily Scripts (${U_S_HOST}): No Deadlock Detected in ${U_DBNAME} at ${CURR_DATE}"
ERR_MSG="Daily Scripts (${U_S_HOST}): ERROR occurred in Monitor Deadlock script in ${U_DBNAME}." 

COM_LOGFILE="${LOG_PATH}/deadlock_mail.lst"
LOGFILE="${LOG_PATH}/deadlock_${DBNAME}.lst"
LOGFILE2="${LOG_PATH}/ora_error.lst"

SQLFILE="${SCRIPT_PATH}/lock.sql"

TXTFILE="${LOG_PATH}"/"deadlock_${DBNAME}.txt"
TXTFILE2="${LOG_PATH}"/"ora_error.txt"
#-------------------------------------------------------------------------
#-------------- Move Old logs to oldlogs directory
${MV} ${LOG_PATH}/*.txt ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.lst ${OLDLOG_PATH}/

CURR_DATE=`date "+%x %X"`
echo " " >> ${COM_LOGFILE}

sqlplus -S << END_SQL
dbmaint/${PWD}@${DBNAME}
set pagesize 1500
set linesize 200
set heading on;
set termout on;
REM set feedback off;
set serveroutput on size 10000;
spool ${LOGFILE}
prompt Starting MONITOR DEADLOCK ...
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
prompt
show user;
select name "Database Name" from v\$database;
select name "Instance Name" from cig_instance;
set timing on;
@${SQLFILE}
prompt
set timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt
prompt MONITOR DEADLOCK Complete.
spool off;
set timing off;
END_SQL

echo " " >> ${COM_LOGFILE}
pg ${LOGFILE} >> ${COM_LOGFILE}

pg ${LOGFILE} |grep ORA- > ${LOGFILE2}

pg ${LOGFILE2}|egrep -vi 'ORA-00000|ORA-00000' > ${TXTFILE2}

if [ -f ${TXTFILE2} ]; then
   BY_CNT=`ls -ltr ${TXTFILE2}|awk '{ print $5 }'`
   if [ ${BY_CNT} != 0 ]; then
      mailx -s "${ERR_MSG}" "${MAIL_LOG_TO_DBA}" < "${COM_LOGFILE}"
      exit 1
   fi
fi

pg ${LOGFILE}|egrep "Oracle User" > ${TXTFILE}

if [ -f ${TXTFILE} ]; then
   RUN_CHECK=`cut -c1-11 ${TXTFILE}| awk '{ print $1,$2 }'`
   echo ${RUN_CHECK} >> ${LOGFILE2}
   RUN_CHECK=`cut -c1-11 ${LOGFILE2}`
   echo ${RUN_CHECK}
   if [ "${RUN_CHECK}" = "Oracle User" ]; then
      CURR_DATE=`date "+%x %X"`
      echo "******* DETECT *******"
      echo " " >> ${COM_LOGFILE}
      mailx -s "${MAIL_LOG_SUB_DETECT}" "${MAIL_LOG_TO_DBA}" < "${COM_LOGFILE}" 
      exit
   else 
      CURR_DATE=`date "+%x %X"`
      #####echo "******* NO DETECT ********"
      #####echo " " >> ${COM_LOGFILE}
      ######mailx -s "${MAIL_LOG_SUB_NO_DETECT}" "${MAIL_LOG_TO_DBA}" < "${COM_LOGFILE}"
   fi
fi
