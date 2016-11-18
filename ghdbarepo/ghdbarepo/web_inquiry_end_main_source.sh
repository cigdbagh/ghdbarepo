# ! /usr/bin/sh
# Name        :  web_inquiry_end_main_source.sh
# Author      :  Sasibhushan Sivasasan
# Description :  This main script used to run all sub scripts for web endorsement process in source host.
#                Script will call the following sub scripts with parameters shown as below:
#                1.chk_end_succ_tri_on_ftpsrv_source.sh <ftp_host> <ftp_username> <ftp_password>
#                2.ftp_web_inquiry_end_source.sh <ftp_host> <ftp_username> <ftp_password> <source_dbname>
#                3.web_inquiry_end_populate_source.sh <dbname> <schema> <password>
#                4.web_inquiry_end_bridge_source.sh <dbname> <schema> <password>
#                5.analyze_tab_indx_end_source.sh <dbname> <schema> <password>
#                Script does the following: 
#                1. Script will check for web_inq_end_target_ftp_succ.dat, created by 
#                   web_inquiry_end_main_target.sh after successful completion of FTP process,
#                   by calling chk_end_succ_tri_on_ftpsrv_source.sh. 
#                   If the dat file exists then script will start the web inquiry process in source host. 
#                   Otherwise script will sleep for 10 minutes. Script will woke up after 10 minutes and
#                   reapeat the checking until the script times out after 1 hours.
#                2. If web_inq_end_target_ftp_succ.dat found in ftp server, script will run 
#                   ftp_web_inquiry_end_source.sh scripts to ftp exp_web_inq_end.dmp export file to 
#                   target host.
#                   Script will check for any error during ftp process and abort if any error occur.
#                3. After successful completion of the FTP process, script will delete exp_web_inq_end.dmp,
#                   web_inq_end_target_ftp_succ.dat from FTP server and create web_inq_end_source_ftp_succ.dat 
#                   in source host.
#                4. Next part of the script will check for web_inq_end_target_ftp_succ.dat and if file found,
#                   script will call web_inquiry_end_populate_source.sh. 
#                5. After successfull completion of web_inquiry_end_populate_source.sh, script will call
#                   web_inquiry_end_bridge_source.sh
#                7. Script will also run  analyze_tab_indx_end_source.sh to analyze all tables and indexes.
#                6. Script will check for all errors during the process and send email with 
#                   logs if any error. Otherwise send mail after successful completion.  
#
# Notes       :  This script require no parameter.
#                Usage of script:
#                sh web_inquiry_end_main_source.sh
#                E.g. sh web_inquiry_end_main_source.sh
#                This script can run from oracle or root user.
#
# Created     :  05/10/04
# Modified    :  06/22/04 - Sasi Sivadasan - Added documentaion
#             :  08/25/04 - Sasi Sivadasan - Documentation modified
#             :  02/11/05 - Sasi Sivadasan - Passwords are removed from scripts for better security and new method introduced.
#             :  02/16/05 - Sasi Sivadasan - Email of jjacobs, tmacdona, mgraziano and kkleven are removed from list
#             :  06/30/05 - Sasi Sivadasan - Email of jjacobs and drivera are added to list
#             :  08/02/05 - Sasi Sivadasan - Email of spavan, cyu and mpanganiban are removed from list
#                03/20/06 - Raman Paul     - Added automatic email address pickup.
#                04/06/06 - kavita         - Email address gsantos@ciginsurance.com removed from MAIL_LOG_TO_USER.
#                11/29/06 - Raman paul     - Gather stats script added in place of the old analyze script.

SCRIPT_PATH="/db/sw/oracle/scripts/web_inquiry/pol_end";export SCRIPT_PATH
ANA_SCR_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export ANA_SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/web_inquiry/pol_end/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/web_inquiry/pol_end/oldlogs";export OLDLOG_PATH
DATA_PATH="/db/data/a26/oracle/web_inquiry/pol_end/export.dir";export DATA_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
E_PATH="/tmp/logs";export E_PATH

FTP_HOST="172.16.201.40"
###FTP_HOST="dmz_ftp"
FTP_USERNAME="cigweb"
#FTP_PASSWORD=`sh ${PWD_PATH}/getfser1.sh`

S_DBNAME="prod"
S_SCHEMA_TMP="agency_tmp"
#S_PASSWORD_TMP=`sh ${PWD_PATH}/getpopn1.sh`

COMM_PATH="/db/data/a3/oracle/${S_DBNAME}/interfaces";export COMM_PATH
S_HOST=`hostname`
U_S_HOST=`echo $S_HOST | tr "[a-z]" "[A-Z]"`
U_FTP_HOST=`echo $FTP_HOST | tr "[a-z]" "[A-Z]"`

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
##MAIL_LOG_TO_USER="${MAIL_lOG_TO_DBA}"
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} mgraziano@ciginsurance.com jamarante@ciginsurance.com bsmith@ciginsurance.com legacysupport@ciginsurance.com"

COMM_LOGFILE="$COMM_PATH"/"web_inquiry_end_detail_${S_HOST}.log"
LOGFILE1="$LOG_PATH"/"ftp_chk_on_src_frm_${FTP_HOST}_to_${S_HOST}.log"
TXTFILE1="$LOG_PATH"/"ftp_chk_on_src_frm_${FTP_HOST}_to_${S_HOST}.txt" 

FILE3="$LOG_PATH"/"web_inq_end_target_ftp_succ.dat"
##FILE4="$LOG_PATH"/"web_inq_end_source_pop_succ.dat"
FILE4="$LOG_PATH"/"web_inquiry_end_extract_target.dat"
FILE5="$LOG_PATH"/"web_inquiry_end_bridge_source_succ.dat"

MAIL_LOG_SUB1="Web Endorsement Failed in ($U_S_HOST): Trigger File ${FILE4} not found."
MAIL_LOG_SUB2="Web Endorsement Failed in ($U_S_HOST): Trigger File ${FILE5} not found."

M_FILE3="web_inq_end_target_ftp_succ.dat"
M_FILE4="web_inq_end_source_pop_succ.dat"

mv $LOG_PATH/*_end_*.txt $OLDLOG_PATH/
mv $LOG_PATH/*_end_*.log $OLDLOG_PATH/
mv $LOG_PATH/*_end_*.lst $OLDLOG_PATH/
mv $LOG_PATH/*_end_*.dat $OLDLOG_PATH/
mv $LOG_PATH/*_end_*.err $OLDLOG_PATH/

CURR_DATE=`date "+%c"`
echo " " > $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** Web Endorsement Process in ${U_S_HOST} Started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
echo "________________________________________________________________________________ " >> $COMM_LOGFILE

CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE
#Here the logic of hp4 endorsement goes
sh $SCRIPT_PATH/web_inquiry_end_extract_target.sh ${S_DBNAME} ${S_SCHEMA_TMP}
if [ -f $FILE4 ]
then
     sh $SCRIPT_PATH/web_inquiry_end_bridge_source.sh ${S_DBNAME} ${S_SCHEMA_TMP}
     if [ -f $FILE5 ]
     then
    	 sh $ANA_SCR_PATH/analyze_schema.sh ${S_DBNAME} ${S_SCHEMA_TMP} 
     else
mailx -s "$MAIL_LOG_SUB2" "$MAIL_LOG_TO_DBA" <<EOF

Trigger File $FILE5 not found. Please check the logs.

Thanks

DBA Team
EOF
     fi
else
mailx -s "$MAIL_LOG_SUB1" "$MAIL_LOG_TO_DBA" <<EOF

Trigger File $FILE4 not found. Please check the logs.

Thanks

DBA Team
EOF
fi
