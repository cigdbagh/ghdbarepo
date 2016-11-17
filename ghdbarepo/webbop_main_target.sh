# ! /bin/sh
# Name        :  webbop_main_target.sh
# Author      :  Sasibhushan Sivasasan
# Description :  This is a main script used to run all sub script for WebBop Admin data refresh process in target host.
#                Script will call the following sub scripts with parameters shown as below:
#                1.webbop_populate_target.sh <dbname> <schema> <password>
#                2.webbop_update_target.sh <dbname> <schema> <password>
#                3.analyze_tab_indx_target.sh <dbname> <schema> <password>
#                Script do the following: 
#                1. Script will check for webbop_source_ftp_succ.dat created by webbop_source_main.sh
#                   after successful completion of FTP process.
#                   If the dat file exists then script will start the web inquiry process in target host. 
#                   Otherwise script will sleep for 5 minutes. Script will woke up after 5 minutes
#                   reapeat the checking until the script times out after 75 minutes.
#                2. If webbop_source_ftp_succ.dat found in target host script will call webbop_populate_target.sh.
#                3. After successfull completion of webbop admin data population in WEBAPPT schema, script will call
#                   webbop_update_target.sh
#                4. After completion of both webbop_populate_target.sh and webbop_update_target.sh, analyze_tab_indx_target.sh
#                   script will run to analyze all tables and indexes in the main schema.
#                5. Script will check for all errors during the whole process and send email with 
#                   logs if any error or complete successfully.  
#
# Notes       :  This script require no parameter.
#                Usage of script:
#                sh webbop_main_target.sh
#                E.g. sh webbop_main_target.sh
#                This script can run from oracle or root user.
#
# Created     :  08/19/05
# Modified    :  08/24/05 - Sasi Sivadasan - Added documentaion
# Modified    :  11/27/06 - Harpreet Singh - Removed passwords as parameters to scripts
#             :  01/22/07 - Raman Paul     - Changed oracle home from 9.2.0 to 11.1.0/db_1

SCRIPT_PATH="/db/sw/oracle/scripts/webapp/webbop/rh4_webbop";export SCRIPT_PATH
ANA_SCR_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export ANA_SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/webapp/webbop/rh4_webbop/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/webapp/webbop/rh4_webbop/oldlogs";export OLDLOG_PATH
DATA_PATH="/db/data/a26/oracle/webapp/webbop/export.dir";export DATA_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
E_PATH="/tmp/logs";export E_PATH
MV="/bin/mv"

T_DBNAME=golf
T_SCHEMA_TMP=webappt
T_SCHEMA_MAIN=cigadmin

COMM_PATH="/db/data/a3/oracle/${T_DBNAME}/interfaces";export COMM_PATH
T_HOST=`hostname`
U_T_HOST=`echo $T_HOST | tr "[a-z]" "[A-Z]"`
U_FTP_HOST=`echo $FTP_HOST | tr "[a-z]" "[A-Z]"`

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} bsmith@ciginsurance.com dbagroup@ciginsurance.com ushirdhankar@ciginsurance.com"

COMM_LOGFILE="$COMM_PATH"/"webbop_dtl_${T_HOST}.log"

FILE1="$DATA_PATH"/"webbop_source_extract_succ.dat"
##FILE1="$DATA_PATH"/"webbop_source_ftp_succ.dat"
FILE2="$LOG_PATH"/"webbop_populate_succ.dat"

M_FILE5="webbop_source_ftp_succ.dat"

$MV $LOG_PATH/*.txt $OLDLOG_PATH/
$MV $LOG_PATH/*.log $OLDLOG_PATH/
#$MV $LOG_PATH/*.lst $OLDLOG_PATH/
$MV $LOG_PATH/*.dat $OLDLOG_PATH/
$MV $LOG_PATH/*.sql $OLDLOG_PATH/
#$MV $LOG_PATH/*.err $OLDLOG_PATH/

CURR_DATE=`date "+%c"`
echo "============================================================ " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** WebBop Admin Refresh in ${U_T_HOST} Started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
do
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
echo "* Starting FTP Success Check in ${U_T_HOST} at ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
### echo "________________________________________________________________________________ " >> $COMM_LOGFILE
if [ -f $FILE1 ]
   then
   sh $SCRIPT_PATH/webbop_populate_target.sh ${T_DBNAME} ${T_SCHEMA_TMP} 
   if [ -f $FILE2 ]
      then
      sh $SCRIPT_PATH/webbop_update_target.sh ${T_DBNAME} ${T_SCHEMA_TMP} 
#####    sh $SCRIPT_PATH/analyze_tab_indx_target.sh ${T_DBNAME} ${T_SCHEMA_MAIN} 
####Ramesh##      sh $ANA_SCR_PATH/analyze_schema.sh ${T_DBNAME} ${T_SCHEMA_MAIN}
   fi;
   exit 1
else
    if [ "$i" != 16 ]
       then
       CURR_DATE=`date "+%c"`
       echo " " >> $COMM_LOGFILE
       echo "* The ${M_FILE5} Not Found in ${U_T_HOST} on $CURR_DATE: Sleeping for 5 minutes" >> $COMM_LOGFILE
       echo " " >> $COMM_LOGFILE
       sleep 300
       # sleep 900
    else 
       echo " " >> $COMM_LOGFILE
       CURR_DATE=`date "+%c"`
       echo "* The ${M_FILE5} Not Found on ${U_T_HOST}: Process Timed Out on ${CURR_DATE}" >> $COMM_LOGFILE
       echo " " >> $COMM_LOGFILE
       echo "________________________________________________________________________________ " >> $COMM_LOGFILE
       echo " " >> $COMM_LOGFILE
       CURR_DATE=`date "+%c"`
       echo "*** WebBop Admin Refresh in ${U_T_HOST} Failed on ${CURR_DATE}" >> $COMM_LOGFILE
       echo " " >> $COMM_LOGFILE
       echo "============================================================ " >> $COMM_LOGFILE
       MAIL_LOG_TIMEOUT="WebBop Admin Refresh ($U_T_HOST): Process in ${U_T_HOST} Failed on ${CURR_DATE}"
       mailx -s "$MAIL_LOG_TIMEOUT" "$MAIL_LOG_TO_USER" < "$COMM_LOGFILE"
       exit 1
   fi
fi
done
