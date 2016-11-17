# ! /usr/bin/sh
# Name        :  dbc_download_main.sh
# Author      :  Harpreet Singh 
# Description :  The purpose of this shell script is to populate the dbc_detail and agent tables and
#                create the dbc_{date(YYYYMMDD)} extract file.
#                This particular shell script is used to call dbc_download.sh and ftp_dbc_download.sh 
#                shell scripts. This script will check for two conditions. First script looks for YYYYMMDDcig.dld 
#                file. If the file exists then script will check for total bytes. If file exists and bytes 
#                are greater than zero, process will abort and script will email the error message. If the 
#                file exists with zero bytes this script will call dbc_download.sh to populate the 
#                desired tables and create the dbc_{date} extract file.
#                Usage of the script is 'sh dbc_download_main.sh'.
#------------------------------------------------------------------
# Notes       :  This script need to change to pass the parameters according to requirement. 
#                Syntax to change the scripts:
#                sh dbc_download.sh <dbname> <schema> 
#                sh ftp_dbc_download.sh <hostname> <username> <password> <dbname>
#                dbname      - name of database
#                schema      - name of schema need to pupulate
#                password    - password for the schema/user
#                hostname    - taget hostname to send the file
#                username    - user in target host to connect
#                password    - password for target host user
#                E.g. sh dbc_download.sh foxtrot agency_tmp 
#                     sh ftp_dbc_download.sh ftp_server cigweb guessme foxtrot
#                This script can run from oracle or root user.
# 
# Created     :  01/23/08 
#
# Modified    :  09/01/09 - Raman Paul -- Removed Marsh Bricker's email and added Paul Zimmerman to the list.
#-------------------------------------------------------------------------
SCRIPT_PATH="/db/sw/oracle/scripts/dbc_download";export SCRIPT_PATH
LOG_PATH="/db/sw/oracle/scripts/dbc_download/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/dbc_download/oldlogs";export OLDLOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
E_PATH="/tmp/logs";export E_PATH
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
MV="/bin/mv"
FILE_DATE=`date "+%Y%m%d"`

S_DBNAME="prod"
S_SCHEMA="agency_tmp"

##FTP_HOST="cigads1"
##FTP_HOST="216.228.2.61"
##FTP_USERNAME="transfer"

##FTP_HOST="172.16.209.74"
FTP_HOST="cigadsup"
FTP_USERNAME="dbaextract"

COMM_PATH="/db/data/a3/oracle/${S_DBNAME}/interfaces";export COMM_PATH
COMM_LOGFILE="${COMM_PATH}"/"dbc_download_${S_HOST}.log"
LOGFILE1="${E_PATH}"/"dbc_download_${S_HOST}.log"

DATAFILE1="${COMM_PATH}"/"dbc_CIM_${FILE_DATE}.dld"
M_DATAFILE1="dbc_CIM_${FILE_DATE}.dld"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} mgraziano@ciginsurance.com dalberg@ciginsurance.com"

MAIL_LOG_SUB1=" W A R N I N G: Policy download - ${M_DATAFILE1} file already exists with greater than zero bytes."

${MV} ${LOG_PATH}/*.txt ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.log ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.lst ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.dat ${OLDLOG_PATH}/

FILE1="$LOG_PATH"/"dbc_download_succ.dat"


CURR_DATE=`date "+%c"`
echo "============================================================ " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** DBC Download Process in ${U_S_HOST} started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
echo "* Checking ${M_DATAFILE1} file already exists with greater than zero bytes" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE

if [ -f ${DATAFILE1} ]
   then
   BY_CNT=`ls -ltr ${DATAFILE1}|awk '{ print $5 }'`
   if [ ${BY_CNT} != 0 ]
      then
      echo " " > $COMM_LOGFILE
      echo "W A R N I N G: ${M_DATAFILE1} file already exists with greater than zero bytes." >> $COMM_LOGFILE
      echo "Processing was stopped. Notify the Application Programmer." >> $COMM_LOGFILE
      echo " " >> $COMM_LOGFILE
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
      exit 1
   else
      sh $SCRIPT_PATH/dbc_download.sh ${S_DBNAME} ${S_SCHEMA} 
      if [ -f $FILE1 ]
         then
         sh $SCRIPT_PATH/ftp_dbc_download.sh ${FTP_HOST} ${FTP_USERNAME} ${S_DBNAME}
      fi
   fi
else
    sh $SCRIPT_PATH/dbc_download.sh ${S_DBNAME} ${S_SCHEMA} 
    if [ -f $FILE1 ]
        then
        sh $SCRIPT_PATH/ftp_dbc_download.sh ${FTP_HOST} ${FTP_USERNAME} ${S_DBNAME}
    fi
fi
