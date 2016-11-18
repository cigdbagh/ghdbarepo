#!/bin/sh
# Author   :  Ramesh Kalyandrug
# Name     :  fix_sequences.sh
# Desc     :  This script looks for negative number in  CURRENT_SEQUENCE_VALUES.TXT. It will create script to do alter sequences .
# created  :  09/22/09
# Modified :  xxxxxxxxx -- xxxxxxxxxxxxxxxxxxxxxxxxxxx

#LOG_PATH="/db/sw/oracle/backup/logs";export LOG_PATH
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
PWD_PATH="/db/sw/oracle/scripts"
MAIL_LOG_SUB1="Summay of Process Running by Each User--- ${U_S_HOST}"
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
LOG_PATH="/db/sw/oracle/scripts/db_maint/logs"; export LOG_PATH
LOG_FILE="${LOG_PATH}"/"user_process_${U_S_HOST}.lst"
SCR_PATH="/db/sw/oracle/scripts/db_maint/db_monitor"; export SCR_PATH
###########################
sh $SCR_PATH/user_process.sh > $LOG_FILE
##########
mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
