#!/bin/sh
# Name     :  pkg_monitor_idle_sessions_umsapp.sh
# Author   :  Raman Paul 
# Created  :  05/10/10
# Desc     :  This particular Shell script is used to monitor database sessions which are idle for
#             more than 3:45 hours. If there are any session in the database which are idle for more
#             than the specified amount of time, than send an email to the DBA team, with all the user 
#             details. This script also insert user about these users into database table named idle_session_log.
#             The ORACLE_SID and p_path should be modified to the database
#             which these procedures are run across.
#             This script runs from Monday-Saturday at XXXXXX
# Modified :   02/25/13 - Raman Paul - Added a call to another sql scritp SCR_FILE4 to get a report of all application users from PROD. I have not added any loggin for this report.

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH
INTERFACES="/db/data/a3/oracle/${DBNAME}/interfaces";export INTERFACES

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

SCR_FILE="${SCR_PATH}"/"check_idle_sessions_umsapp.sql"
SCR_FILE2="${SCR_PATH}"/"ins_idle_sessions_report_scr_umsapp.sql"
SCR_FILE3="${SCR_PATH}"/"gen_html_report_umsapp.sql"
SCR_FILE4="${SCR_PATH}"/"gen_html_report_app_users.sql"
LOG_FILE2="${LOG_PATH}"/"check_idle_sessions_${SCHEMA}_${DBNAME}_umsapp.lst"
TXT_FILE2="${LOG_PATH}"/"check_idle_sessions_${SCHEMA}_${DBNAME}_umsapp.txt"
ERR_FILE2="${LOG_PATH}"/"check_idle_sessions_${SCHEMA}_${DBNAME}_umsapp.err"

LOG_FILE="${LOG_PATH}"/"pkg_monitor_idle_sessions_${SCHEMA}_${DBNAME}_umsapp.lst"
TXT_FILE="${LOG_PATH}"/"pkg_monitor_idle_sessions_${SCHEMA}_${DBNAME}_umsapp.txt"

LOG_FILE3="${LOG_PATH}"/"ins_idle_sessions_report_${SCHEMA}_${DBNAME}_umsapp.lst"
TXT_FILE3="${LOG_PATH}"/"ins_idle_sessions_report_${SCHEMA}_${DBNAME}_umsapp.txt"

LOG_FILE4="${LOG_PATH}"/"gen_html_report_${SCHEMA}_${DBNAME}_umsapp.lst"
TXT_FILE4="${LOG_PATH}"/"gen_html_report_${SCHEMA}_${DBNAME}_umsapp.txt"

RM_LOG="${LOG_PATH}"/"rm_pkg_monitor_idle_sessions_${S_HOST}_umsapp.log"
UTL_FILE="${INTERFACES}"/"idle_session_log_umsapp.html"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"
##*##MAIL_LOG_TO_DBA="rpaul@ciginsurance.com"
##*##MAIL_LOG_TO_DBAGRP="${MAIL_LOG_TO_DBA}"
##*##MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Daily Script (${U_S_HOST}): ERROR on pkg_monitor_idle_sessions_umsapp in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Data Script (${U_S_HOST}): Pkg_monitor_idle_sessions_umsapp completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Daily Script (${U_S_HOST}): ERROR in pkg_monitor_idle_sessions_umsapp logs."

if [ -f ${UTL_FILE} ]
   then
   $RM ${UTL_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${LOG_FILE} ]
   then
   $RM ${LOG_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${LOG_FILE2} ]
   then
   $RM ${LOG_FILE2} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${LOG_FILE3} ]
   then
   $RM ${LOG_FILE3} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${LOG_FILE4} ]
   then
   $RM ${LOG_FILE4} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
set linesize 120
set pagesize 1000
column username format a10
spool ${LOG_FILE2}
@${SCR_FILE}
spool off;
END_SQL

if [ -f ${ERR_FILE2} ]
   then
   $RM ${ERR_FILE2} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${TXT_FILE2} ]
   then
   $RM ${TXT_FILE2} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

pg ${LOG_FILE2}|grep "no rows selected" > ${TXT_FILE2}
	 if [ -f ${TXT_FILE2} ]
	   then
	   RUN_CHECK=`cut -c1-16 ${TXT_FILE2}`
	     if [ "$RUN_CHECK" = "no rows selected" ]
             then
                exit 1
             else
echo "Came to the procedure execution"
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting PKG_MONITOR_IDLE_SESSIONS ... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
execute PKG_MONITOR_IDLE_SESS_UMSAPP.sp_monitor_idle;  
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_MONITOR_IDLE_SESSIONS complete.
spool off;
END_SQL
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

pg ${LOG_FILE}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE}
   if [ -f ${TXT_FILE} ]
      then
	 RUN_CHECK=`cut -c1-40 ${TXT_FILE}`
	    if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
	  then
	mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
 echo " exiting"
      exit 1
    fi
 echo " Came to second package execution"
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
set linesize 120
set pagesize 1000
SET SERVEROUTPUT ON
--column username format a10
spool ${LOG_FILE4}
@${SCR_FILE3}
--execute print_table ( 'select * from idle_session_log');
--execute print_table ( 'select username,idle_time_hr,idle_time_min from idle_session_log');
--execute print_table ( 'select username,idle_time_hr,idle_time_min from idle_session_log where last_modified > sysdate-.04');
spool off;
END_SQL
fi
if [ -f ${TXT_FILE3} ]
   then
      $RM ${TXT_FILE3} > ${RM_LOG}
	 STATUS="$?"
    if [ "${STATUS}" != 0 ]; then
  mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
	exit 1
   fi
fi
if [ -f ${TXT_FILE4} ]
   then
      $RM ${TXT_FILE4} > ${RM_LOG}
	 STATUS="$?"
    if [ "${STATUS}" != 0 ]; then
  mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
	exit 1
   fi
fi

pg ${LOG_FILE4}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE4}
   if [ -f ${TXT_FILE4} ]
      then
	 RUN_CHECK=`cut -c1-40 ${TXT_FILE4}`
	    if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
	  then
	mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE4}"
      exit 1
    else
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
set linesize 120
set pagesize 1000
SET SERVEROUTPUT ON
--column username format a10
@${SCR_FILE4}
END_SQL
     # mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE3}"
     exit 1
     fi
  fi
fi
