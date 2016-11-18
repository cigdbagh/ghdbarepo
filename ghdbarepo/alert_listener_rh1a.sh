#!/bin/sh
# Name     : alert_listener.sh
# Author   : Ramesh Kalyandrug
# created  : 09/26/13
# Modified :
####################################

ORACLE_TERM=vt100;export ORACLE_TERM
LOG_PATH="/db/sw/oracle/scripts/db_maint/db_monitor/logs";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

LSNR="/u01/app/oracle/product/12.1.0.2/db_1/bin/lsnrctl";export LSNR
SRVCTL="/u01/app/grid/12.1.0.2/bin/srvctl";export SRVCTL
LSNR_GRID="/u01/app/grid/12.1.0.2/bin/lsnrctl";export LSNR_GRID

LOG_FILE="${LOG_PATH}/alert_listener_rh1a.lst"
TXT_FILE="${LOG_PATH}/alert_listener_rh1a.txt"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="DBA - Production Listener  Down  : Listener down for   ${U_S_HOST}"
MAIL_LOG_SUB2="DBA - Production Listener  Check : alert_listener.sh completed in ${U_S_HOST}"
MAIL_LOG_SUB3="DBA - Production Listener  Check : Please verify Listener Status  in ${U_S_HOST}"
#. /u01/app/oracle/.profile
. /home/oracle/.profile
${SRVCTL} status scan_listener > $LOG_FILE
${LSNR_GRID} status LISTENER >> $LOG_FILE
# . /home/oracle/.profile_db
#${LSNR} status LISTENER_DG_RH1A >> $LOG_FILE

##### Error Handling #######
pg ${LOG_FILE} |grep "disabled"  > ${TXT_FILE}
pg ${LOG_FILE} |grep "TNS-"   >> ${TXT_FILE}

CURR_DATE=`date "+%c"`
###*###ORATAB=/etc/oratab
echo "`date`   "

if [ -f ${TXT_FILE} ]; then
       #BY_CNT=`ls -ltr ${TXTFILE1}|awk '{ print $5 }'`
       BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
       if [ ${BY_CNT} != 0 ]; then
          #mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
          mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
       exit 1
          ##  else
         ## mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBA}"
       fi
fi
