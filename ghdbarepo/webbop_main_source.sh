# ! /usr/bin/sh
# Name        :  webbop_main_source.sh
# Author      :  Sasibhushan Sivasasan
# Description :  This is the main and starting script for webbop process. This script used to run 
#                webbop_extract_source.sh and ftp_webbop_source.sh shell scripts. 
#                This is the only one script, which has the database name, schema name, password
#                and target host details. 
#                Script has the following variables: database name, schema name, password for schema, 
#                source host name retrieved from system, ftp server hostname/IP address, user name in 
#                ftp host and password of user in ftp host. Ftp server is the target host for this script. This is 
#                global script, which can use for any host, any database and any user/schema using the 
#                parameters accordingly.
#                Usage of the script is 'sh webbop_main_source.sh'.
# Notes       :  Parameters needs to change in this script acccording to requirement.
#                Syntax to change the scripts:
#                sh webbop_extract_source.sh <dbname> <schema> <password>
#                sh ftp_webbop_source.sh <hostname> <username> <password> <dbname>
#                dbname      - name of source database
#                schema      - name of source schema need to pupulate
#                password    - password for the schema/user
#                hostname    - taget hostname to send the file
#                username    - user in target host to connect
#                password    - password for target host user
#                E.g. sh webbop_extract_source.sh alpha webappt guessme
#                     sh ftp_webbop_source.sh ftp_server oracle guessme alpha
#                This script can run from oracle or root user.
# Created     :  08/19/05
# Modified    :  09/06/05 - Sasi - Added documentaion
#             :  03/20/06 - Raman Paul - Added automatic email address pickup. 
# Modified    :  11/27/06 - Harpreet Singh - Removed Passwords as paramters to scripts

SCRIPT_PATH="/db/sw/oracle/scripts/webapp/webbop";export SCRIPT_PATH 
LOG_PATH="/db/sw/oracle/scripts/webapp/webbop/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/webapp/webbop/oldlogs";export OLDLOG_PATH
DATA_PATH="/db/data/a26/oracle/webapp/webbop/export.dir";export DATA_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
E_PATH="/tmp/logs";export E_PATH
S_HOST=`hostname`
U_S_HOST=`echo $S_HOST | tr "[a-z]" "[A-Z]"`
MV="/bin/mv"

S_DBNAME="prod" 
S_SCHEMA="webappt" 

###FTP_HOST="172.16.201.32"
##FTP_HOST="hp4"
FTP_HOST="rh4"
####FTP_HOST="172.16.201.32"
FTP_USERNAME="oracle"

COMM_PATH="/db/data/a3/oracle/${S_DBNAME}/interfaces";export COMM_PATH
COMM_LOGFILE="$COMM_PATH"/"webbop_dtl_${S_HOST}.log"
LOGFILE1="$E_PATH"/"webbop_${S_HOST}.log"

DATAFILE1="$DATA_PATH"/"exp_webbop.dmp"
M_DATAFILE1="exp_webbop.dmp"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
##*##MAIL_LOG_TO_DBA="${MAIL_LOG_TO_DBA}"
MAIL_LOG_TO_DBA="${MAIL_LOG_TO_DBA} ushirdhankar@ciginsurance.com bsmith@ciginsurance.com"

MAIL_LOG_SUB1="WebBop ($U_S_HOST): Export file already exists with greater than zero bytes."

$MV $LOG_PATH/*.txt $OLDLOG_PATH/
$MV $LOG_PATH/*.log $OLDLOG_PATH/
$MV $LOG_PATH/*.lst $OLDLOG_PATH/
$MV $LOG_PATH/*.dat $OLDLOG_PATH/
$MV $LOG_PATH/*.sql $OLDLOG_PATH/

CURR_DATE=`date "+%c"`
echo "============================================================== " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** WebBop Process in ${U_S_HOST} started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================== " >> $COMM_LOGFILE
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
echo "* Checking ${M_DATAFILE1} file already exists with greater than zero bytes" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
if [ -f $DATAFILE1 ]
   then
   BY_CNT=`ls -ltr $DATAFILE1|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      echo " " >> $COMM_LOGFILE
      echo "* Processing was stopped. Please check $COMM_LOGFILE for more details." >> $COMM_LOGFILE
      echo " " >> $COMM_LOGFILE
      mailx -s "$MAIL_LOG_SUB1" "$MAIL_LOG_TO_DBA" < "$COMM_LOGFILE"
      exit 1
   else
      echo " " >> $COMM_LOGFILE
      echo "* ${M_DATAFILE1} file with zero bytes.  Process continued..." >> $COMM_LOGFILE
      echo " " >> $COMM_LOGFILE
      echo "________________________________________________________________________________ " >> $COMM_LOGFILE
      sh $SCRIPT_PATH/webbop_extract_source.sh $S_DBNAME $S_SCHEMA 
      sh $SCRIPT_PATH/ftp_webbop_source.sh $FTP_HOST $FTP_USERNAME $S_DBNAME
   fi
else
      echo " " >> $COMM_LOGFILE
      echo "* ${M_DATAFILE1} file does not exists.  Processing continued..." >> $COMM_LOGFILE
      echo " " >> $COMM_LOGFILE
      echo "________________________________________________________________________________ " >> $COMM_LOGFILE
      sh $SCRIPT_PATH/webbop_extract_source.sh $S_DBNAME $S_SCHEMA 
      sh $SCRIPT_PATH/ftp_webbop_source.sh $FTP_HOST $FTP_USERNAME $S_DBNAME
fi
