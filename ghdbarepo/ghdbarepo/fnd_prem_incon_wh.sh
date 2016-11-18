#!/bin/sh
# Name     :  fnd_prem_incon_wh.sh
# Author   :  Ramesh Kalyandrug
# Created  :  05/13/16 
#Requested : Rajeev

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="whouse"
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE="${LOG_PATH}"/"FND_PREM_INCON_WH${SCHEMA}_${DBNAME}.lst"
LOG_FILE1="${LOG_PATH}"/"FND_PREM_INCON_Final${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"FND_PREM_INCON_WH${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"RM_FND_PREM_INCON_WH${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
#MAIL_LOG_TO_DBAGRP="gpisari@ciginsurance.com"
#MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_DBAGRP="${MAIL_LOG_TO_DBA} rbijalwan@ciginsurance.com"
MAIL_LOG_TO_USER="rbijalwan@ciginsurance.com,agrover@ciginsurance.com,scasey@ciginsurance.com, jasmith@ciginsurance.com, mye@ciginsurance.com, kkleven@ciginsurance.com, bsmith@ciginsurance.com, ppletcher@ciginsurance.com, dmoskala@ciginsurance.com,ssivadasan@ciginsurance.com ALamont@ciginsurance.com TSmall@ciginsurance.com gpisari@ciginsurance.com"
#MAIL_LOG_TO_USER="gpisari@ciginsurance.com"
#MAIL_LOG_SUB1="Premium difference and data inconstancies daily report  (${U_S_HOST}): ERROR on FND_PREM_INCON_WH in ${U_SCHEMA} of ${U_DBNAME}"
#MAIL_LOG_SUB2="Premium difference and data inconstancies daily report (${U_S_HOST}): FND_PREM_INCON_WH completed in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Action Required -Differences Between eCig and Data Warehouse"
MAIL_LOG_SUB1="No Differences Between eCig and Data Warehouse"
RM_ERR="Daily Scripts (${U_S_HOST}): ERROR in removing FND_PREM_INCON_WH logs."

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
--spool ${LOG_FILE}
set pagesize 500
set linesize 500
prompt Starting FND_PREM_INCON_WH  ... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
--set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
spool ${LOG_FILE}
@$SCR_PATH/fnd_prem_incon_wh.sql;
--set time off timing off;
--SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
--prompt FND_PREM_INCON_WH complete.
spool off;
END_SQL

if [ -f ${TXT_FILE} ]
   then
   $RM ${TXT_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBAGRP}" < "${RM_LOG}"
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_USER}" < "${RM_LOG}"
      exit 1
   fi
fi

pg ${LOG_FILE}|grep "Action Required" > ${TXT_FILE}

cat ${LOG_FILE} | egrep -vi "PL/SQL procedure successfully completed." > ${LOG_FILE1}
if [ -f ${TXT_FILE} ]
   then
   RUN_CHECK=`cut -c1-15 ${TXT_FILE}`
   if [ "${RUN_CHECK}" != "Action Required" ]
      then
#     mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE1}"
#     mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE1}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE}"
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      exit 1
   fi
fi
exit
