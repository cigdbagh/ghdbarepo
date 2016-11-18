#!/bin/sh
# Name     :  pkg_eliens.sh
# Author   :  Raman Paul 
# Created  :  01/29/2007
# Desc     :  This script is used to execute pkg_eliens.The scripts creates an output file in the interfaces directory.
#             The ORACLE_SID and p_path should be modified to the database which these packages are run across.
#             This script will run daily from the Cron. 
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID=prod;export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
RM="/bin/rm"

DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
PWD=`sh ${PWD_PATH}/getpopn1.sh`

CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE="${LOG_PATH}"/"pkg_eliens_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"pkg_eliens_${SCHEMA}_${DBNAME}.txt"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER=`sh ${PWD_PATH}/mail_log_to_dba.sh`

#MAIL_LOG_TO_DBA="rkalyandrug@ciginsurance.com" 
#MAIL_LOG_TO_DBAGRP="rkalyandrug@ciginsurance.com" 
#MAIL_LOG_TO_USER="rkalyandrug@ciginsurance.com" 

MAIL_LOG_SUB1="Daily Scripts (${U_S_HOST}): ERROR on pkg_eliens.sp_main in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Scripts (${U_S_HOST}): Pkg_eliens.sp_main completed in ${U_SCHEMA} of ${U_DBNAME}"

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting PKG_ELIENS.SP_MAIN... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
set time on timing on;
execute pkg_eliens.sp_main;
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_ELIENS.SP_MAIN complete.
spool off;
END_SQL

pg ${LOG_FILE}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   RUN_CHECK=`cut -c1-40 ${TXT_FILE}`
   if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE}"
      exit 1
   fi
fi

