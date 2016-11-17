#!/bin/sh
# Name     :  pg_umbrella_policy_verify.sh
# Author   :  Ganga
# Created  :  01/19/2012
# Desc     :  This particular shell script is used to run cms_adjuster_fix procedure.
#             The ORACLE_SID and p_path should be modified to the database 
#             which these procedures are run across.
#             This script runs weekly on Friday at 05:35

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`
SCR_FILE="${SCR_PATH}"/"cms_adjuster_assignment_fix.sql"
LOG_FILE="${LOG_PATH}"/"cms_adjuster_fix_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"cms_adjuster_fix_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_cms_adjuster_fix_${S_HOST}.log"
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} jamarant@ciginsurance.com"

MAIL_LOG_SUB1="(${U_S_HOST}): ERROR on cms_adjuster_fix in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="(${U_S_HOST}): cms_adjuster_fix completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="(${U_S_HOST}): ERROR in removing cms_adjuster_fix logs."

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
prompt Starting cms_adjuster_fix... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
@${SCR_FILE}
---execute cms_adjuster_fix();
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt cms_adjuster_fix complete.
spool off;
END_SQL

if [ -f ${TXT_FILE} ]
   then
   $RM ${TXT_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

pg ${LOG_FILE}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   RUN_CHECK=`cut -c1-40 ${TXT_FILE}`
   if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      exit 1
   fi
fi


