#!/bin/sh
# Name     :  daily_error_check.sh
# Author   :  Sasi Sivadasan
# created  :  07/11/05
# Desc     :  This particular Shell script is used to check the errors in data fix script logs.
#             This script runs from cron on from M-F at 16:45 and 17:25
#             Script include scripting standards like variables, error checking, logging, desc, password hiding and 
#             and mailing the logs etc. 
#             Passwords are removed from scripts for better security and new method introduced.
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
# Modified :  03/02/06 - Sasi Sivadasan - Error messages changed to upper case letters.
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 11.1.0/db_1
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`

ERR_FILE="${LOG_PATH}"/"daily_error_check_${S_HOST}.err"
TXT_FILE="${LOG_PATH}"/"daily_error_check_${S_HOST}.txt"
RM_LOG="${LOG_PATH}"/"rm_daily_error_check_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="DAILY ERROR CHECK (${U_S_HOST}): ERROR ON DAILY ERROR CHECK. Please check the logs"
MAIL_LOG_SUB2="Daily Error Check (${U_S_HOST}): No error found in logs"
RM_ERR="Daily Error Check (${U_S_HOST}): ERROR in removing Daily error check logs"

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

pg ${LOG_PATH}/*.* |grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00000|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      CURR_DATE=`date "+%x %X"`
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < ${TXT_FILE}
      echo "Error on Daily Error Check on ${CURR_DATE}"
      exit 1
   else
   CURR_DATE=`date "+%x %X"`
 mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" <<EOF
No errors on log files. Daily error check completed successfully on ${CURR_DATE}
Thank you
EOF
echo "Daily Error Check completed successfully on ${CURR_DATE}"
      exit 1
   fi
fi
