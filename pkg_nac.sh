#!/bin/sh
# Name     :  pkg_nac.sh
# Author   :  Sasi Sivadasan 
# Created  :  02/15/2006
# Desc     :  This script is used to run pkg_nac.
#             The ORACLE_SID and p_path should be modified to the database which these packages is run across.
#             This script runs on Wednesday at 20:30
#	   :  03/20/06 - kavita		- changed the path from 8.1.6 - 11.1.0/db_1
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH
BKUP_PATH="/db/data/a26/oracle/nac/old_nac"

CP="/bin/cp"
FILE_TIME=`date "+%H%M%S"`
FILE_DATE=`date "+%m%d%Y"`

DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
PWD=`sh ${PWD_PATH}/getpopn1.sh`
COMM_PATH="/db/data/a3/oracle/${DBNAME}/interfaces";export COMM_PATH

CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE="${LOG_PATH}"/"pkg_nac_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"pkg_nac_${SCHEMA}_${DBNAME}.txt"
DATAFILE1="${COMM_PATH}"/"nac.csv"
M_DATAFILE1="nac.csv"
OLDFILE1="${BKUP_PATH}"/"nac_${FILE_DATE}_${FILE_TIME}.csv"
CP_LOG="${LOG_PATH}"/"nac_cp.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} operators@ciginsurance.com"

MAIL_LOG_SUB1="NAC Towing (${U_S_HOST}): ERROR on pkg_nac.sp_main in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="NAC Towing (${U_S_HOST}): Pkg_nac.sp_main completed in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB3="NAC Towing (${U_S_HOST}): Error on copying ${M_DATAFILE1} file to ${OLDFILE1}."

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting PKG_NAC.SP_MAIN... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
--select 'PL/SQL procedure successfully completed.' from dual;
execute pkg_nac.sp_main;
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PKG_NAC.SP_MAIN complete.
spool off;
END_SQL

FILE_TIME=`date "+%H%M%S"`
FILE_DATE=`date "+%m%d%Y"`
OLDFILE1="${BKUP_PATH}"/"nac_${FILE_DATE}_${FILE_TIME}.csv"

pg ${LOG_FILE}|grep "PL/SQL procedure successfully completed." > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   RUN_CHECK=`cut -c1-40 ${TXT_FILE}`
   if [ "${RUN_CHECK}" != "PL/SQL procedure successfully completed." ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
      exit 1
   else
      FILE_TIME=`date "+%H%M%S"`
      FILE_DATE=`date "+%m%d%Y"`
      OLDFILE1="${BKUP_PATH}"/"nac_${FILE_DATE}_${FILE_TIME}.csv"
      ${CP} ${DATAFILE1} ${OLDFILE1} > ${CP_LOG}
      STATUS="$?"
      if [ "$STATUS" != 0 ]; then
         mailx -s "${MAIL_LOG_SUB3}" "${MAIL_LOG_TO_DBA}" < "${CP_LOG}"
         exit 1
      fi
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE}"
      exit 1
   fi
fi

