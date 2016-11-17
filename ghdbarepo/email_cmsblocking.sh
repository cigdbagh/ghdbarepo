#!/bin/sh
# Name     :  kill_session_${SPLSCHEMA}.sh
# Author   :  Harpreet Singh
# created  :  04/15/10
# Desc     :  This particular Shell script is used to kill sessions.
#             This script is manully run by DBA when required. Also scheduled in cron on Saturday at 15:30
# Modified :  02/02/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included. Modified to generate the SQL script dynamically in main script.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME="/u01/app/oracle/product/12.1.0.2/db_1";export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="dbmaint"
RM="/bin/rm"
# CURR_DATE=`date "+%x %X"`
CURR_DATE=`date "+%D %T"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

MIME_FILE="${SCR_PATH}"/"mime_prod.sh"
AWK_FILE="${SCR_PATH}"/"text2html.awk"

SPLSCHEMA="cmsapp"

COM_FILE="${LOG_PATH}"/"com_log_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.lst"
SCR_FILE1="${SCR_PATH}"/"ins_sess_data_${SPLSCHEMA}.sql"
LOG_FILE1="${LOG_PATH}"/"ins_sess_data_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.lst"
SCR_FILE2="${LOG_PATH}"/"kill_session_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.sql"
LOG_FILE2="${LOG_PATH}"/"kill_session_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.lst"
SCR_FILE3="${SCR_PATH}"/"sample_sess_info_${SPLSCHEMA}.sql"
LOG_FILE3="${LOG_PATH}/kill_sess_report_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.lst"
LOG_FILE4="${LOG_PATH}/kill_sess_report_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.html"
HTML_FILE="${LOG_PATH}/kill_sess_report_${SPLSCHEMA}_${SCHEMA}_${DBNAME}_mail.html"

ERR_FILE="${LOG_PATH}"/"kill_session_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.err"
TXT_FILE="${LOG_PATH}"/"kill_session_${SPLSCHEMA}_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_kill_session_${SPLSCHEMA}_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
##*##MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} skar@ciginsurance.com CIGDBCHANGES@valuemomentum.biz"
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="eDBA - Daily Scripts (${U_S_HOST}): ERROR on kill_session_${SPLSCHEMA}.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): kill_session_${SPLSCHEMA}.sql completed in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB3="eDBA - Daily Scripts (${U_S_HOST}): ERROR on generating kill_session_${SPLSCHEMA}.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB4="eDBA - Daily Scripts (${U_S_HOST}): ERROR on ins_sess_data_${SPLSCHEMA}.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB5="eDBA - Daily Scripts (${U_S_HOST}): ERROR on sample_sess_info_${SPLSCHEMA}.sql in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="CMS Session Problem Started........Killing the hung session"

if [ -f ${COM_FILE} ]
   then
   $RM ${COM_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${LOG_FILE1} ]
   then
   $RM ${LOG_FILE1} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
show user;
select name from v\$pdbs;
select to_char(sysdate,'MM/DD/YYYY hh24:MI:SS') Datetime from dual;
select name instance_name from cig_instance;
set pagesize 1000;
set linesize 100;
spool ${SCR_FILE2}
set head off
--select 'Checking CMSAPP for a hung session........' from dual;
--set head on;
---select username "Username",sid "Session ID"  
--------select 'alter system kill session '''||s.sid||','||s.serial#||''' immediate; '----------
----------- Altered kill session script for RAC database ----------
select 'alter system kill session '''||s.sid||','||s.serial#||',@'||inst_id||''' immediate; '
from gv\$session s
where
        s.username is not null
        and s.username not in ('SYS','SYSTEM','DBSNMP','CIGADMIN','WHOUSE','AGENCY','AGENCY_TMP','DBMAINT','CALLIGO52','CALLIGODRT',
'DBFIX')
        and s.sid in (select sw.sid from gv\$session_wait sw where sw.event in ('SQL*Net more data from client'))
        and s.username='CMSAPP' and status!='KILLED'
/
spool off;
END_SQL
check_blocking_session=`grep 'no rows selected' $SCR_FILE2`
if [ "$check_blocking_session" != "no rows selected" ]
then
echo "" >> $COM_FILE
echo "CMSAPP hung session found.......Killing the session" >> $COM_FILE
echo "" >> $COM_FILE
pg ${SCR_FILE2} >> $COM_FILE
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
show user;
select name from v\$pdbs;
select to_char(sysdate,'MM/DD/YYYY hh24:MI:SS') Datetime from dual;
select name instance_name from cig_instance;
set pagesize 1000;
set linesize 100;
set head off;
set feedback on;
spool ${LOG_FILE2}
--select 'CMSAPP session problem started....Killing the hung session' from dual;
@${SCR_FILE2}
spool off;
END_SQL
pg ${LOG_FILE2} >> ${COM_FILE}
	mailx -s "${RM_ERR}" "$MAIL_LOG_TO_USER" < "${COM_FILE}"
fi
