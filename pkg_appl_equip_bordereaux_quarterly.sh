#!/bin/sh
# Name     :  pkg_appl_equip_bordereaux_quarterly.sh
# Author   :  Raman Paul
# created  :  1/04/2010
# Desc     :  This particular shell script is used to run pkg_appl_equip_bordereaux script. Requested by Joyce Burnett.
#             The ORACLE_SID and p_path should be modified to the database which these procedures are run across.
#             This script runs on the 1st of every month. the script calculate data variables on the basis of dates 
#             in server and the database. If the dates are correct then runs the script, otherwise notify the 
#             application programmer. 
# Modified :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

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

COMM_LOGFILE="${LOG_PATH}"/"pkg_appl_equip_bordereaux_quarterly_common.log"
LOG_FILE1="${LOG_PATH}"/"pkg_appl_equip_bordereaux_quarterly_${SCHEMA}_${DBNAME}.lst"
ERR_FILE1="${LOG_PATH}"/"pkg_appl_equip_bordereaux_quarterly_${SCHEMA}_${DBNAME}.err"
TXT_FILE1="${LOG_PATH}"/"pkg_appl_equip_bordereaux_quarterly_${SCHEMA}_${DBNAME}.txt"
RM_LOG="${LOG_PATH}"/"rm_pkg_appl_equip_bordereaux_quarterly_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} jburnett@ciginsurance.com"
##*##MAIL_LOG_TO_DBA="rpaul@ciginsurance.com"
##*##MAIL_LOG_TO_DBAGRP="rpaul@ciginsurance.com"
##*##MAIL_LOG_TO_USER="rpaul@ciginsurance.com jburnett@ciginsurance.com"

MAIL_LOG_SUB1="Quarterly Script (${U_S_HOST}): ERROR on pkg_appl_equip_bordereaux_mon in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Quarterly Script (${U_S_HOST}): pkg_appl_equip_bordereaux_mon completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Quarterly Script (${U_S_HOST}): ERROR in removing pkg_appl_equip_bordereaux_mon log."

QUARTER_START_DATE=`sqlplus -S << END_SQL
   ${SCHEMA}/${PWD}@${DBNAME}
   set head off
   set pagesize 0
   set feedback off
   set linesize 100
   select to_char(trunc(add_months(sysdate,-3),'MM'),'DD-MON-YYYY') "quarter_start_date" from dual;
   --SELECT to_char(trunc(add_months(sysdate,-3)),'DD-MON-YYYY') "quarter_start_date" FROM dual;
   --set feedback on
   --set head on
END_SQL`
echo ${QUARTER_START_DATE}

QUARTER_END_DATE=`sqlplus -S << END_SQL
   ${SCHEMA}/${PWD}@${DBNAME}
   set head off
   set pagesize 0
   set feedback off
   set linesize 100
   SELECT TO_CHAR(TRUNC(SYSDATE, 'MM')-1, 'DD-MON-YYYY') "quarter_end_date" FROM dual;
   --set feedback on
   --set head on
END_SQL`
echo ${QUARTER_END_DATE}

if [ -f ${COMM_LOGFILE} ]
   then
   $RM ${COMM_LOGFILE} > ${RM_LOG}
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
       CURR_DATE=`date "+%x %X"`
       echo " " >> ${COMM_LOGFILE}
       echo "##########################################################################" >> ${COMM_LOGFILE}
       echo " " >> ${COMM_LOGFILE}
       echo "* Quarterly pkg_appl_equip_bordereaux started in ${U_DBNAME} on ${CURR_DATE}" >> ${COMM_LOGFILE}
       echo " " >> ${COMM_LOGFILE}
       echo "*  First day of previous quarter is ${QUARTER_START_DATE} and last day of previous quarter is ${QUARTER_END_DATE}" >> ${COMM_LOGFILE} 
       echo " " >> ${COMM_LOGFILE}
       echo "##########################################################################" >> ${COMM_LOGFILE}
       echo " " >> ${COMM_LOGFILE}

sqlplus -S << END_SQL
       ${SCHEMA}/${PWD}@${DBNAME}
       spool ${LOG_FILE1}
       prompt Starting pkg_appl_equip_bordereaux_quarterly...
       SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
       show user;
       select name database from v\$pdbs;
       select name instance_name from cig_instance;
       --- set serveroutput on ;
       set time on timing on;
   --- select 'PL/SQL procedure successfully completed.' from dual;
BEGIN
       pkg_appl_equip_bordereaux.sp_appl_equip_quarterly_prem('${QUARTER_START_DATE}','${QUARTER_END_DATE}');
       pkg_appl_equip_bordereaux.sp_appl_equip_quarterly_claim('${QUARTER_START_DATE}','${QUARTER_END_DATE}');
       pkg_appl_equip_bordereaux.sp_farm_appleqp_qrtly_claim('${QUARTER_START_DATE}','${QUARTER_END_DATE}');
       pkg_appl_equip_bordereaux.sp_farm_appleqp_qrtly_prem('${QUARTER_START_DATE}','${QUARTER_END_DATE}');
END;
/
       set time off timing off;
       SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
       prompt pkg_appl_equip_bordereaux_quarterly complete.
       spool off;
END_SQL

if [ -f ${ERR_FILE1} ]
   then
   $RM ${ERR_FILE1} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
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
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${LOG_FILE1}"
      exit 1
      else
         CURR_DATE=`date "+%x %X"`
         echo " " >> ${COMM_LOGFILE}
         pg ${LOG_FILE1} >> ${COMM_LOGFILE}
         echo " " >> ${COMM_LOGFILE}
         mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
   fi
fi
