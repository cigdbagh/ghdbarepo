#!/bin/sh
# Name     :  claimdrafts.sh
# Author   :  Gretchen Norton
# Created  :  4-15-1999
# Desc     :  This particular shell script is used to execute a procedure to create interface file for Claims Drafts.
#             This script execute pkg_draft.sp_write_claim_draft in CIGADMIN schema.
#             The ORACLE_SID and p_path should be modified to the database which these procedures are run across.
#             This script runs from Monday-Friday at 05:15
# Modified :  06/26/02 - Sasi Sivadasan - Parameter added as per the request from Todd. 
#          :  09/13/02 - Sasi Sivadasan - Parameter removed as per the request from Todd. 
#          :  02/09/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards.
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included.
#                                         Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
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
SCHEMA="cigadmin"
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE1="${LOG_PATH}"/"pkg_drft_sp_wrt_cla_drft_${SCHEMA}_${DBNAME}.lst"
TXT_FILE1="${LOG_PATH}"/"pkg_drft_sp_wrt_cla_drft_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_drft_sp_wrt_cla_drft_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Daily Scripts (${U_S_HOST}): ERROR on pkg_draft.sp_write_claim_draft in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): Pkg_draft.sp_write_claim_draft completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Daily Scripts (${U_S_HOST}): ERROR in removing pkg_draft.sp_write_claim_draft logs."

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
spool ${LOG_FILE1}
prompt Starting PKG_DRAFT.SP_WRITE_CLAIM_DRAFT... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
execute pkg_draft.sp_write_claim_draft;
commit;
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_DRAFT.SP_WRITE_CLAIM_DRAFT complete.
spool off;
END_SQL

if [ -f ${TXT_FILE1} ]
   then
   $RM ${TXT_FILE1} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

pg ${LOG_FILE1}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE1}
if [ -f ${TXT_FILE1} ]
   then
   RUN_CHECK=`cut -c1-40 ${TXT_FILE1}`
   if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE1}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE1}"
      exit 1
   fi
fi
