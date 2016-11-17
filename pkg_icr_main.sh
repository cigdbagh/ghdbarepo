#!/bin/sh
# Name     :  pkg_icr_main.sh
# Author   :  Shashi Pavan
# Created  :  10/02/01
# Desc     :  This particular shell script is used to execute pkg_icr.sp_write_icr, which generate ICR report for the EDD.
#             The ORACLE_SID and path should be modified to the database which these procedures are run across.
#             This script runs on first Monday after every 10th and 25th at 07:15
# Modified :  02/09/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included. Script modified include the mailing part in the main script.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  02/05/08 - Raman Paul     - cschwarz@ciginsurance.com removed from email list.  

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
TODAY=`date "+%m%d%Y"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

INT_PATH="/db/data/a3/oracle/${DBNAME}/interfaces";export INT_PATH
LOG_FILE="${LOG_PATH}"/"pkg_icr_sp_write_icr_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"pkg_icr_sp_write_icr_${SCHEMA}_${DBNAME}.txt"

MSG_FILE1="${SCR_PATH}"/"icr_error_file.lst"  # Static file
MSG_FILE2="${SCR_PATH}"/"icr_file.lst"        # Static file
ICR_FILE="${INT_PATH}"/"ICR_${TODAY}.TXT"
RM_LOG="${LOG_PATH}"/"rm_icr_file_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} techsupport@ciginsurance.com ushirdhankar@ciginsurance.com"
MAIL_LOG_SUB1="ICR Report (${U_S_HOST}): The ICR file not Generated in ${U_SCHEMA} of ${U_DBNAME}, check for errors"
MAIL_LOG_SUB2="ICR Report (${U_S_HOST}): The ICR report file (ICR_$TODAY.TXT) for EDD is generated in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="ICR Report (${U_S_HOST}): ERROR in removing ICR report logs."

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
prompt Starting PKG_ICR.SP_WRITE_ICR... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
execute pkg_icr.sp_write_icr;
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_ICR.SP_WRITE_ICR complete.
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
      if [ -f ${ICR_FILE} ]
         then
         mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${MSG_FILE2}"
         exit 1
      else
         mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${MSG_FILE1}"
         exit 1
      fi
   fi
fi


