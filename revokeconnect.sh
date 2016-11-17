#!/bin/sh
# Name     :  revokeconnect.sh
# Author   :  Shashi Pavan
# created  :  12/30/98
# Desc     :  This particular Shell script is used to revoke access from users.
#             This script is manully run by DBA at 18:30 on working days. Also scheduled in cron on Saturday at 15:00
# Modified :  02/02/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included. Modified to generate the SQL script dynamically in main script.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  03/22/05 - Sasi Sivadasan - Modified the like condition from CALLIGOV43% to CALLIGO%  to avoid the error  
#                                         due to the CALLIGO user existance
#          :  04/01/05 - Shashipavan -    Modified the like condition to add new user DROBARE to access capcom after hours. 
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  01/16/11 - Sasi Sivadasan - UMSAPP user added in the where class of the revoke connect
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
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

SCR_FILE="${LOG_PATH}"/"revokeconnect_${SCHEMA}_${DBNAME}.sql"
LOG_FILE="${LOG_PATH}"/"revokeconnect_${SCHEMA}_${DBNAME}.lst"
ERR_FILE="${LOG_PATH}"/"revokeconnect_${SCHEMA}_${DBNAME}.err"
TXT_FILE="${LOG_PATH}"/"revokeconnect_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_revokeconnect_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="eDBA - Daily Scripts (${U_S_HOST}): ERROR on revokeconnect.sql in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): revokeconnect.sql completed in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB3="eDBA - Daily Scripts (${U_S_HOST}): ERROR on generating revokeconnect.sql in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="eDBA - Daily Scripts (${U_S_HOST}): ERROR in removing revokeconnect log file."

if [ -f ${SCR_FILE} ]
   then
   $RM ${SCR_FILE} > ${RM_LOG}
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

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
spool ${SCR_FILE}
set pagesize 1000;
set linesize 100;
set head off;
set feedback off;
select 'revoke create session from '||username|| ';' from dba_USERS
WHERE ACCOUNT_STATUS!='LOCKED'
AND USERNAME NOT LIKE 'SYS%' AND USERNAME NOT LIKE 'OPER%'
AND USERNAME NOT LIKE 'CIGADM%' AND USERNAME NOT LIKE 'WHOUS%'
AND USERNAME NOT LIKE 'AGENCY%' AND USERNAME NOT LIKE 'AGENCY_TMP%'
AND USERNAME NOT LIKE 'PCVLA%' AND USERNAME NOT LIKE 'BFEAR%'
AND USERNAME NOT LIKE 'JME%' AND USERNAME NOT LIKE 'CALLIGO%'
AND USERNAME NOT LIKE 'YMITTS%' AND USERNAME NOT LIKE 'PPLETCHE%'
AND USERNAME NOT LIKE 'BSMITH' AND USERNAME NOT LIKE 'PCBOASOA'
AND USERNAME NOT LIKE 'LMORIN%' AND USERNAME NOT LIKE 'DROBARE%'
AND USERNAME NOT LIKE 'WEBAPP%' AND USERNAME NOT LIKE 'DBSNMP%'
AND USERNAME NOT LIKE 'WEBBOP%' AND USERNAME NOT LIKE 'BABYBOP%'
AND USERNAME NOT LIKE 'CCBOASO%' AND USERNAME NOT LIKE 'AQSSR%'
AND USERNAME NOT LIKE 'HERMESO%' AND USERNAME NOT LIKE 'WENDALL'
AND USERNAME NOT LIKE 'WENDLTD' AND USERNAME NOT LIKE 'WENDORSE'
AND USERNAME NOT LIKE 'CTXSYS'AND USERNAME NOT LIKE 'XS$NUL%'
AND USERNAME NOT LIKE 'XDB%' AND USERNAME NOT LIKE 'PUBDOMAI%'
AND USERNAME NOT LIKE 'PUBCONSO%' AND USERNAME NOT LIKE 'IDM6%' 
AND USERNAME NOT LIKE 'CHECKBO%' AND USERNAME NOT LIKE 'JJACOB%'
AND USERNAME NOT LIKE 'CMSAPP' AND USERNAME NOT LIKE 'SPOTLIGHT'  
AND USERNAME NOT LIKE 'S_LINK_USE%' AND USERNAME NOT LIKE 'PUBREQUEST'
AND USERNAME NOT LIKE 'CCARRIER' AND USERNAME NOT LIKE 'INSLOOK'
AND USERNAME NOT LIKE 'UMSAPP'
AND USERNAME NOT LIKE 'WEBSRVCS'
AND USERNAME NOT LIKE 'CIGMAINT' AND USERNAME NOT LIKE 'MKODAKAL'
AND USERNAME NOT LIKE 'SARASADA' AND USERNAME NOT LIKE 'RMATONAK'
AND USERNAME NOT LIKE 'EXSTREAM' AND USERNAME NOT LIKE 'MAPPUSE%'
AND USERNAME NOT LIKE 'BCUSER' 
AND USERNAME NOT LIKE 'BPALANIA' 
AND USERNAME NOT LIKE 'ASAXENA' 
AND USERNAME NOT LIKE 'MCWOOD' 
AND USERNAME NOT LIKE 'MGONZALES' 
AND USERNAME NOT LIKE 'ATRIPATH' 
AND USERNAME NOT LIKE 'SHDUTT' 
AND USERNAME NOT LIKE 'MYE' 
AND USERNAME NOT LIKE 'ADOLL' 
AND USERNAME NOT LIKE 'DMOSKALA' 
AND USERNAME NOT LIKE 'JKRUG' 
AND USERNAME NOT LIKE 'RWILLIAM' 
AND USERNAME NOT LIKE 'PBIEWER' 
AND USERNAME NOT LIKE 'BJANITSC' 
AND USERNAME NOT LIKE 'BATCHETL' 
AND USERNAME NOT LIKE 'KPEVERIN' 
AND USERNAME NOT LIKE 'CLOOS' 
ORDER BY USERNAME
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

pg ${SCR_FILE}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00000|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      mailx -s "${MAIL_LOG_SUB3}" "${MAIL_LOG_TO_DBA}" < "${SCR_FILE}"
      exit 1
   else
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting REVOKE CONNECT... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
@${SCR_FILE}
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt REVOKE CONNECT complete.
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
            mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
            exit 1
         else
#             mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE}"
             exit 1
         fi
      fi
   fi
fi
