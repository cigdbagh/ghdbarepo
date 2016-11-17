#!/bin/sh
# Name     :  aplus_monthly.sh
# Author   :  Shashi Pavan (Tested by Marimer Panganiban)
# Created  :  5/17/2002
# Desc     :  This particular shell script is used to execute pkg_aplus.sp_write_aplus_file in CIGADMIN schema.
#             The ORACLE_SID and path should be modified to the database which these procedures are run across.
#             This script runs on the last day of the month at 18:30
# Modified :  07/03/02 - Carolyn Schwarz- Changed to set serveroutput on 
#          :  10/01/02 - Shashi Pavan   - Modified the password of operator 
#          :  05/01/03 - Sasi Sivadasan - Modified the password of operator 
#          :  06/30/03 - Sasi Sivadasan - Modified the script to remove mdowns@ciginsurance.com and add kkleven@ciginsurance.com 
#          :  07/10/03 - Marimer P      - to update Chuck's email 
#          :  07/25/03 - Sasi Sivadasan - Modified the script to change the password for operator 
#          :  10/17/03 - Sasi Sivadasan - Modified the script to removed Carolyn's Email 
#          :  10/20/03 - Sasi Sivadasan - Modified the script to change the password for operator 
#          :  02/10/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  12/15/06 - Raman Paul     - Changed the schema to dbfix. Password also changed and cbmcvay's email removed. 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="dbfix"

RM="/bin/rm"
Month=`date "+%m"`
Year=`date "+%Y"`

CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

INT_PATH="/db/data/a3/oracle/${DBNAME}/interfaces";export INT_PATH

LOG_FILE="${LOG_PATH}"/"run_aplus_extract_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"run_aplus_extract_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_aplus_extract_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} bmitts@ciginsurance.com kkleven@ciginsurance.com"

MAIL_LOG_SUB1="eDBA - Monthly Scripts (${U_S_HOST}): ERROR on pkg_aplus.sp_write_aplus_file in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Monthly Scripts (${U_S_HOST}): Pkg_aplus completed. Please check run_aplus_extract_${SCHEMA}_${DBNAME}.lst & FTP."
RM_ERR="eDBA -  Monthly Scripts (${U_S_HOST}): ERROR in removing pkg_aplus logs."

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
prompt Starting PKG_APLUS.SP_WRITE_APLUS... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
--select name database from v\$pdbs;
--select name instance_name from cig_instance;
set time on timing on;
set serveroutput on;
--select 'PL/SQL procedure successfully completed.' from dual;
execute pkg_aplus.sp_write_aplus_file($Month,$Year,331000000000,'N');
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_APLUS.SP_WRITE_APLUS complete.
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
      cp ${LOG_FILE} ${INT_PATH}
      chmod 777 ${LOG_FILE}
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      cp ${LOG_FILE} ${INT_PATH}
      chmod 777 ${LOG_FILE}
      exit 1
   fi
fi


