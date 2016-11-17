#!/bin/sh
# Name     :  kill_session.sh
# Author   :  Shashi Pavan
# created  :  03/25/02
# Desc     :  This particular Shell script is used to kill sessions.
#             This script is manully run by DBA when required. Also scheduled in cron on Saturday at 15:30
# Modified :  02/02/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included. Modified to generate the SQL script dynamically in main script.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  01/16/11 - Sasi Sivadasan - UMSAPP user added in the where class of the kill session 
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
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

COM_FILE="${LOG_PATH}"/"com_log_${SCHEMA}_${DBNAME}.lst"
SCR_FILE1="${SCR_PATH}"/"ins_sess_data.sql"
LOG_FILE1="${LOG_PATH}"/"ins_sess_data_${SCHEMA}_${DBNAME}.lst"
SCR_FILE2="${LOG_PATH}"/"kill_session_${SCHEMA}_${DBNAME}.sql"
LOG_FILE2="${LOG_PATH}"/"kill_session_${SCHEMA}_${DBNAME}.lst"
SCR_FILE3="${SCR_PATH}"/"sample_sess_info.sql"
LOG_FILE3="${LOG_PATH}/kill_sess_report_${SCHEMA}_${DBNAME}.lst"
LOG_FILE4="${LOG_PATH}/kill_sess_report_${SCHEMA}_${DBNAME}.html"
HTML_FILE="${LOG_PATH}/kill_sess_report_${SCHEMA}_${DBNAME}_mail.html"

ERR_FILE="${LOG_PATH}"/"kill_session_${SCHEMA}_${DBNAME}.err"
TXT_FILE="${LOG_PATH}"/"kill_session_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_kill_session_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="eDBA - Daily Scripts (${U_S_HOST}): ERROR on kill_session.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): kill_session.sql completed in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB3="eDBA - Daily Scripts (${U_S_HOST}): ERROR on generating kill_session.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB4="eDBA - Daily Scripts (${U_S_HOST}): ERROR on ins_sess_data.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB5="eDBA - Daily Scripts (${U_S_HOST}): ERROR on sample_sess_info.sql in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="eDBA - Daily Scripts (${U_S_HOST}): ERROR in removing kill session logs."

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
select name pdbs from v\$pdbs;
select name instance_name from cig_instance;
spool ${LOG_FILE1}
prompt Starting INSERT SESSION DATA...
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name pdbs from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
@${SCR_FILE1}
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt INSERT SESSION DATA complete.
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

if [ -f ${SCR_FILE2} ]
   then
   $RM ${SCR_FILE2} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
       mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
       exit 1
   fi
fi

pg ${LOG_FILE1}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00000|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      mailx -s "${MAIL_LOG_SUB4}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE1}"
      exit 1
   else
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
show user;
select name from v\$pdbs;
select name instance_name from cig_instance;
set pagesize 1000;
set linesize 100;
set head off;
set feedback off;
spool ${SCR_FILE2}
-----------select 'alter system kill session '''||s.sid||','||s.serial#||'''; '---------------
--------- Added new kill session syntax for RAC pdbs --------------
select 'alter system kill session '''||s.sid||','||s.serial#||',@'||inst_id||'''; '
from gv\$session s
where username is not null and username not in ('SYS','SYSTEM','DBSNMP','CIGADMIN','WHOUSE','AGENCY','AGENCY_TMP','JMEUSER','BFEAR','CMCVAY','DBELARDO','OPERATOR','DBMAINT','YMITTS','PPLETCHE','CALLIGO52','CALLIGODRT','LMORIN','DROBARE','WEBAPPT','DBFIX','WEBBOPU','BABYBOPU','WEBAPP','CCBOASOA','AQSSRVCS','PCBOASOA','HERMESOA','WENDORSE','WENDLTD','WENDALL','CTXSYS','PUBDOMAIN','PUBCONSOLE',
'IDM62','CHECKBOX','JJACOBS','CMSAPP','SPOTLIGHT','PUBREQUEST','CCARRIER','INSLOOK','UMSAPP','WEBSRVCS','RMATONAK','EXSTREAM','MAPPUSER','KGRANT','BCUSER','BPALANIA','ASAXENA','MCWOOD','MGONZALES','ATRIPATH','SHDUTT','MYE','ADOLL','DMOSKALA','JKRUG','RWILLIAM','PBIEWER','BJANITSC','BATCHETL','KPEVERIN','CLOOS')
/
spool off;
set head on;
set feedback on;
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

      if [ -f ${LOG_FILE2} ]
         then
         $RM ${LOG_FILE2} > ${RM_LOG}
         STATUS="$?"
         if [ "${STATUS}" != 0 ]; then
            mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
            exit 1
            fi
      fi

      pg ${SCR_FILE2}|grep ORA- > ${ERR_FILE}
      pg ${ERR_FILE}|egrep -vi 'ORA-00030|ORA-00000' > ${TXT_FILE}
      if [ -f ${TXT_FILE} ]
         then
         BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
         if [ $BY_CNT != 0 ]
            then
            mailx -s "${MAIL_LOG_SUB3}" "${MAIL_LOG_TO_DBA}" < "${SCR_FILE2}"
            exit 1
         else
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE2}
prompt Starting KILL SESSION... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name pdbs from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
@${SCR_FILE2}
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt KILL SESSION complete.
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

            pg ${LOG_FILE2}|grep ORA- > ${ERR_FILE}
            pg ${ERR_FILE}|egrep -vi 'ORA-00030|ORA-00000' > ${TXT_FILE}
            if [ -f ${TXT_FILE} ]
               then
               BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
               if [ $BY_CNT != 0 ]
                  then
                  mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE2}"
                  exit 1
#               else
#                  mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE2}"
#                  exit 1
               fi
            fi
        fi
     fi
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

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE3}
prompt Starting SAMPLE SESSION INFO... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name pdbs from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
@${SCR_FILE3}
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt SAMPLE SESSION INFO complete.
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

pg ${LOG_FILE3}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00030|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      mailx -s "${MAIL_LOG_SUB5}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE3}"
      exit 1
   else
      touch ${COM_FILE}
      pg ${LOG_FILE1} > ${COM_FILE}
      echo " " >> ${COM_FILE}
      pg ${LOG_FILE2} >> ${COM_FILE}
      echo " " >> ${COM_FILE}
      pg ${LOG_FILE3} >> ${COM_FILE}
      ${AWK_FILE} ${COM_FILE} > ${LOG_FILE4}
      cat ${MIME_FILE} ${LOG_FILE4} > ${HTML_FILE}
      mail "${MAIL_LOG_TO_DBAGRP}" < "${HTML_FILE}"
      exit 1
   fi
fi
