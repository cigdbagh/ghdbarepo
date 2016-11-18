#!/bin/sh
# Name     :  daily_main.sh
# Author   :  Sasi Sivadasan
# created  :  03/28/07
# Desc     :  This shell script is used to run automated daily processing.
#             This script is run from cron on every day at 21:01
# Modified :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/month_end";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/month_end/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="whouse"
RM="/bin/rm"
CURR_DATE=`date '+%m%d%y'`
CURR_TIME=`date '+%H%M%S'`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

SCR_FILE="${SCR_PATH}"/"daily_populate.sql"
LOG_FILE="${LOG_PATH}"/"daily_pop_${DBNAME}_${CURR_DATE}_${CURR_TIME}.lst"
ERR_FILE="${LOG_PATH}"/"daily_pop_${DBNAME}_${CURR_DATE}_${CURR_TIME}.err"
TXT_FILE="${LOG_PATH}"/"daily_pop_${DBNAME}_${CURR_DATE}_${CURR_TIME}.txt"
RM_LOG="${LOG_PATH}"/"rm_daily_populate_${S_HOST}.log"
ERR_DOC="${SCR_PATH}"/"daily_hand_over_err.doc"
SUC_DOC="${SCR_PATH}"/"daily_hand_over_succ.doc"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
##*##MAIL_LOG_TO_DBA="${MAIL_LOG_TO_DBA} kkleven@ciginsurance.com ppletcher@ciginsurance.com ymitts@ciginsurance.com"
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} kkleven@ciginsurance.com ppletcher@ciginsurance.com jmeek@ciginsurance.com lmorin@ciginsurance.com"
#MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} rkalyandrug@ciginsurance.com"
##*##MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Daily (${U_S_HOST}): ERROR on daily_populate.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily (${U_S_HOST}): Daily_populate.sql completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Daily (${U_S_HOST}): ERROR in removing daily_populate log."

if [ -f ${LOG_FILE} ]
   then
   $RM ${LOG_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting DAILY POPULATE 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
set serveroutput on;
@${SCR_FILE}
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt DAILY POPULATE complete.
prompt
spool off;
END_SQL

if [ -f ${ERR_FILE} ]
   then
   $RM ${ERR_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${TXT_FILE} ]
   then
   $RM ${TXT_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
       mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
       exit 1
   fi
fi

pg ${LOG_FILE}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00000|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      pg ${ERR_DOC} >> ${LOG_FILE}
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      exit 0
   else
      pg ${SUC_DOC} >> ${LOG_FILE}
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      exit 1
   fi
fi
