#!/bin/sh
# Name     :  kill_sniped_session.sh
# Author   :  Marimer Panganiban
# Created  :  5/28/2003
# Desc     :  This script is originally based from the script provided in metalink.
#             This script kills sessions that have been sniped. This should run when killing other sessions
#             as part of the steps before turning over the database to operations.
#             This script can also be scheduled in the cron to kill sniped sessions during the day.
#             The ORACLE_SID and p_path should be modified to the database which these packages are run across.
#             This script runs on Monday-Friday at 11:30, 14:30 and 16:30
# Modified :  02/14/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included.
#                                         Passwords are removed from scripts for better security and new method introduced.
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  01/14/14 - Ramesh         - Modified script to run in RAC env.
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx
ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/db_maint";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/db_maint/logs";export LOG_PATH

RM="/bin/rm"
DBNAME=${ORACLE_SID}
SCHEMA="dbmaint"
PWD=`sh ${PWD_PATH}/getpopn1.sh`
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE1="${LOG_PATH}"/"before_killing_sniped_${SCHEMA}_${DBNAME}.lst"
LOG_FILE2="${LOG_PATH}"/"kill_sniped_session_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"kill_sniped_session_${SCHEMA}_${DBNAME}.txt"
ERR_FILE="${LOG_PATH}"/"kill_sniped_session_${SCHEMA}_${DBNAME}.err"
RM_LOG="${LOG_PATH}"/"rm_kill_sniped_session_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Daily Scripts (${U_S_HOST}): ERROR on kill_sniped_session in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): Kill_sniped_session completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Daily Scripts (${U_S_HOST}): ERROR in removing kill_sniped_session log."

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE1}
prompt Starting BEFORE_KILL_SNIPPED_SESSION... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set pagesize 1000;
set linesize 100;
select p.spid, s.username, s.status from gv\$process p,gv\$session s
where s.paddr=p.addr
and s.status='SNIPED' and p.inst_id=1;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt BEFORE_KILL_SNIPPED_SESSION complete.
prompt 
prompt Starting KILL_SNIPPED_SESSION....
spool off;
set head off;
set feedback off;
spool ${LOG_FILE2}
select p.spid from gv\$process p,gv\$session s
where s.paddr=p.addr
and s.status='SNIPED' and p.inst_id=1;
spool off;
set feedback on;
set head on;
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

pg ${LOG_FILE2}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00030|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE2}"
      exit 1
   else
      for x in `cat ${LOG_FILE2} | grep "^[0123456789]"`
      do
         kill $x
      done
      pg ${LOG_FILE2} >> ${LOG_FILE1}
      echo "KILL_SNIPPED_SESSION complete." >> ${LOG_FILE1}
#      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE1}"
      exit 1
   fi
fi
