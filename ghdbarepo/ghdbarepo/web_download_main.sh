# ! /usr/bin/sh
# Name        :  web_download_main.sh
# Author      :  Sasibhushan Sivasasan
# Description :  The purpose of this shell script is to populate the web_download table and
#                create the web_download extract file.
#
#                This particular shell script is used to call web_download.sh and ftp_web_download.sh 
#                shell scripts. This script will check for two conditions. First script looks for YYYYMMDDcig.dld 
#                file. If the file exists then script will check for total bytes. If file exists and bytes 
#                are greater than zero, process will abort and script will email the error message. If the 
#                file exists with zero bytes this script will call web_download.sh to populate the 
#                web_download table and create the web_download extract file.
#                Usage of the script is 'sh web_download_main.sh'.
# 
# Notes       :  This script need to change to pass the parameters according to requirement. 
#                Syntax to change the scripts:
#                sh web_download.sh <dbname> <schema> <password>
#                sh ftp_web_download.sh <hostname> <username> <password> <dbname>
#                dbname      - name of database
#                schema      - name of schema need to pupulate
#                password    - password for the schema/user
#                hostname    - taget hostname to send the file
#                username    - user in target host to connect
#                password    - password for target host user
#                E.g. sh web_download.sh foxtrot agency_tmp guessme
#                     sh ftp_web_download.sh ftp_server cigweb guessme foxtrot
#                This script can run from oracle or root user.
# 
# Created     :  03/18/02
#
# Modified    :  10/17/02 - Sasi Sivadasan - Added cyu@ciginsurance.com to email list
#                12/19/02 - Sasi Sivadasan - Removed cschwarz@ciginsurance.com from email list
#                09/23/03 - Sasi Sivadasan - New modification to this script is the concept of passing parameters
#                                            and make reusable in any database. This is the only one script, 
#	                                     which is having the database name, username, password and host names. 
#                                            Second addition to the script is including a common log file, which will 
#                                            be send along with email notification. This is the main script, which will 
#                                            call web_download.sh and ftp_web_download.sh with parameters.
#                11/21/05 - Sasi Sivadasan - Scripts are redesigned with new scripting standard. New scripts will check all 
#                                            errors and generate the common log file, which is used to email to users. 
#                                            Password hiding feature included. New emails are added.
#                04/06/06 - kavita         - Email address gsantos@ciginsurance.com removed from MAIL_LOG_TO_USER
#                00/00/00 - xxxx - xxxxxxxxxxxxxxxxxx
# Modified    :  11/02/06 - Harpreet Singh - Commented Password Variables and removed password variables passed as paramteres to
#                Scripts 

SCRIPT_PATH="/db/sw/oracle/scripts/web_download";export SCRIPT_PATH
LOG_PATH="/db/sw/oracle/scripts/web_download/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/web_download/oldlogs";export OLDLOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
E_PATH="/tmp/logs";export E_PATH
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
MV="/bin/mv"
FILE_DATE=`date "+%Y%m%d"`

S_DBNAME="prod"
S_SCHEMA="agency_tmp"
#S_PASSWORD=`sh ${PWD_PATH}/getpopn1.sh`

##FTP_HOST="cigads1"
##FTP_HOST="216.228.2.61"
##FTP_USERNAME="transfer"
##FTP_PASSWORD=`sh ${PWD_PATH}/getads1ser.sh`

FTP_HOST="cigadsup"
####FTP_HOST="172.16.209.74"
FTP_USERNAME="dbaextract"
FTP_PASSWORD=`sh ${PWD_PATH}/getcigadsupser.sh`

COMM_PATH="/db/data/a3/oracle/${S_DBNAME}/interfaces";export COMM_PATH
####COMM_PATH="/db/data/a3/oracle/lima/interfaces";export COMM_PATH
COMM_LOGFILE="${COMM_PATH}"/"web_download_${S_HOST}.log"
LOGFILE1="${E_PATH}"/"web_download_${S_HOST}.log"

DATAFILE1="${COMM_PATH}"/"${FILE_DATE}cig.dld"
M_DATAFILE1="${FILE_DATE}cig.dld"

DATAFILE2="${COMM_PATH}"/"cim_${FILE_DATE}cig.dld"
M_DATAFILE2="cim_${FILE_DATE}cig.dld"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
##MAIL_LOG_TO_DBA="hsingh@ciginsurance.com rpaul@ciginsurance.com"
##MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1=" W A R N I N G: Policy download - ${M_DATAFILE1} file already exists with greater than zero bytes."
MAIL_LOG_SUB2=" W A R N I N G: Policy download - ${M_DATAFILE2} file already exists with greater than zero bytes."

${MV} ${LOG_PATH}/*.txt ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.log ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.lst ${OLDLOG_PATH}/
${MV} ${LOG_PATH}/*.dat ${OLDLOG_PATH}/

FILE1="$LOG_PATH"/"web_download_succ.dat"
FILE2="${LOG_PATH}"/"web_download_succ2.dat"

CURR_DATE=`date "+%c"`
echo "============================================================ " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** Web Download Process in ${U_S_HOST} started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
echo "* Checking ${M_DATAFILE1} file already exists with greater than zero bytes" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
fileexists="no"
BY_CNT=0
BY_CNT2=0
if [ -f ${DATAFILE1} ]
then
   fileexists="yes"
   BY_CNT=`ls -ltr ${DATAFILE1}|awk '{ print $5 }'`
fi
if [ -f ${DATAFILE2} ]
then
   fileexists="yes"
   BY_CNT2=`ls -ltr ${DATAFILE2}|awk '{ print $5 }'`
fi
if [ "${fileexists}" = "yes" ]
then
   if [ "${BY_CNT}" != 0 -o "${BY_CNT2}" != 0 ]
   then
      if [ "${BY_CNT}" != 0 -a "${BY_CNT}" != "" ]
      then
      	echo " " > $COMM_LOGFILE
#     # 	echo "W A R N I N G: ${M_DATAFILE1} file already exists with greater than zero bytes." >> $COMM_LOGFILE
      	echo "Processing was stopped for ${M_DATAFILE1}. Notify the Application Programmer." >> $COMM_LOGFILE
      	echo " " >> $COMM_LOGFILE
      	mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
##        exit 1 
      fi 
      if [ "${BY_CNT2}" != 0 -a "${BY_CNT2}" != "" ]
      then
        echo " " > $COMM_LOGFILE
        echo "W A R N I N G: ${M_DATAFILE2} file already exists with greater than zero bytes." >> $COMM_LOGFILE
        echo "Processing was stopped for ${M_DATAFILE2}. Notify the Application Programmer." >> $COMM_LOGFILE
        echo " " >> $COMM_LOGFILE
        mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
##  	exit 1 
     fi 
   else
      sh $SCRIPT_PATH/web_download.sh ${S_DBNAME} ${S_SCHEMA} 
      if [ -f $FILE1 -o -f $FILE2 ]
         then
             sh $SCRIPT_PATH/ftp_web_download.sh ${FTP_HOST} ${FTP_USERNAME} ${FTP_PASSWORD} ${S_DBNAME}
             echo "Skip Ftp of File"
      fi
   fi
else
    sh $SCRIPT_PATH/web_download.sh ${S_DBNAME} ${S_SCHEMA}  
    if [ -f $FILE1 -o -f $FILE2 ]
        then
            sh $SCRIPT_PATH/ftp_web_download.sh ${FTP_HOST} ${FTP_USERNAME} ${FTP_PASSWORD} ${S_DBNAME}
            echo  "Skip Ftp Of File"
    fi
fi
