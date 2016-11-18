# ! /usr/bin/sh
# Name        :  web_inquiry_main_source.sh
# Author      :  Sasibhushan Sivasasan
# Description :  This is the main and starting script for web inquiry process. This script used to run 
#                web_inquiry_extract_source.sh and ftp_web_inquiry_source.sh shell scripts. 
#                This is the only one script, which has the database name, schema name, password
#                and target host details. 
#                Script has the following variables: database name, schema name, password for schema, 
#                source host name retrieved from system, ftp server hostname/IP address, user name in 
#                ftp host password in ftp host. Ftp server is the target host for this script. This is 
#                global script, which can use for any host, any database and any user/schema using the 
#                parameters accordingly.
#                Usage of the script is 'sh web_inquiry_main_source.sh'.
#
# Notes       :  This script needs parameter changes according to requirement.
#                Syntax to change the scripts:
#                sh web_inquiry_extract_source.sh <dbname> <schema> <password>
#                sh ftp_web_inquiry_source.sh <hostname> <username> <password> <dbname>
#                dbname      - name of source database
#                schema      - name of source schema need to pupulate
#                password    - password for the schema/user
#                hostname    - taget hostname to send the file
#                username    - user in target host to connect
#                password    - password for target host user
#                E.g. sh web_inquiry_extract_source.sh prod agency_tmp guessme
#                     sh ftp_web_inquiry_source.sh ftp_server cigweb guessme prod
#                This script can run from oracle or root user.
# Created     :  02/10/03
#
# Modified    :  02/18/03 - Sasi - Added documentaion
#                09/10/03 - Sasi - Modified to include new FTP server logic and script name changes.
#                00/00/00 - xxxx - xxxxxxxxxxxxxxxxxx
#             :  07/14/04 - Sasi - Modified to include new logic, documentation and modified script names.
#                                  For more details refer VSS/DBA/Web_inquiry/[hostname]/Web_inquiry[_Dev]
#             :  03/01/05 - Sasi Sivadasan - Passwords are removed from scripts for better security and new method introduced.
#             :  03/01/05 - Sasi Sivadasan - Email of jjacobs, tmacdonald,mgraziano and kkleven are removed from list
#             :  08/02/05 - Sasi Sivadasan - Email of spavan, cyu and mpanganiban are removed and jjacobs and drivera are added
#                00/00/00 - xxxx - xxxxxxxxxxxxxxxxxx
# Modified    :  11/01/06 - Harpreet Singh - commented FTP_PASSWORD and S_PASSWORD variables and removed as parameters

SCRIPT_PATH="/db/sw/oracle/scripts/web_inquiry";export SCRIPT_PATH 
LOG_PATH="/db/sw/oracle/scripts/web_inquiry/logs";export LOG_PATH
OLDLOG_PATH="/db/sw/oracle/scripts/web_inquiry/oldlogs";export OLDLOG_PATH
DATA_PATH="/db/data/a26/oracle/web_inquiry/export.dir";export DATA_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
ANA_SCR_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export ANA_SCR_PATH
E_PATH="/tmp/logs";export E_PATH
S_HOST=`hostname`
U_S_HOST=`echo $S_HOST | tr "[a-z]" "[A-Z]"`
MV="/bin/mv"

S_DBNAME="prod"
S_SCHEMA="agency_tmp" 
#S_PASSWORD=`sh ${PWD_PATH}/getpopn1.sh`
S_SCHEMA_MAIN="agency"

# FTP_HOST="209.232.226.162"
FTP_HOST="172.16.201.40"
###FTP_HOST="dmz_ftp"
FTP_USERNAME="cigweb"
#FTP_PASSWORD=`sh ${PWD_PATH}/getfser1.sh`

COMM_PATH="/db/data/a3/oracle/${S_DBNAME}/interfaces";export COMM_PATH
COMM_LOGFILE="$COMM_PATH"/"web_inquiry_dtl_${S_HOST}.log"
LOGFILE1="$E_PATH"/"web_inquiry_${S_HOST}.log"

DATAFILE1="$DATA_PATH"/"exp_web_inquiry.dmp"
M_DATAFILE1="exp_web_inquiry.dmp"

TRIG_FILE="$LOG_PATH"/"web_inq_source_extract_succ.dat"
TRIG_FILE2="${LOG_PATH}"/"web_inquiry_update_target_succ.dat"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
##MAIL_LOG_TO_USER=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} mgraziano@ciginsurance.com jamarante@ciginsurance.com bsmith@ciginsurance.com"

MAIL_LOG_SUB1="Web Inquiry Failed in ($U_S_HOST): Trigger File ${TRIG_FILE} not found."
MAIL_LOG_SUB2="Web Inquiry Failed in ($U_S_HOST): Trigger File ${TRIG_FILE2} not found."

$MV $LOG_PATH/*.txt $OLDLOG_PATH/
$MV $LOG_PATH/*.log $OLDLOG_PATH/
$MV $LOG_PATH/*.lst $OLDLOG_PATH/
$MV $LOG_PATH/*.dat $OLDLOG_PATH/
$MV $LOG_PATH/*.sql $OLDLOG_PATH/

CURR_DATE=`date "+%c"`
echo "============================================================ " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "*** Web Inquiry Process in ${U_S_HOST} started on ${CURR_DATE}" >> $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo "============================================================ " >> $COMM_LOGFILE
CURR_DATE=`date "+%x %X"`
echo " " >> $COMM_LOGFILE

sh $SCRIPT_PATH/web_inquiry_extract_source.sh $S_DBNAME $S_SCHEMA 
if [ -f ${TRIG_FILE} ]
then
	##Script for web_inquiry_update_target
	sh $SCRIPT_PATH/web_inquiry_update_target.sh $S_DBNAME $S_SCHEMA_MAIN 
	if [ -f ${TRIG_FILE2} ]
	then
		##Analyze
        	sh $ANA_SCR_PATH/analyze_schema.sh $S_DBNAME ${S_SCHEMA_MAIN} 
		CTSPATH="/db/sw/oracle/scripts/copy_table"
		sh ${CTSPATH}/phone_table_import.sh
	else
mailx -s "$MAIL_LOG_SUB2" "$MAIL_LOG_TO_DBA" <<EOF

Trigger File $TRIG_FILE2 not found. Please check the logs.

Thanks

DBA Team
EOF
	fi
else
mailx -s "$MAIL_LOG_SUB1" "$MAIL_LOG_TO_DBA" <<EOF

Trigger File $TRIG_FILE not found. Please check the logs.

Thanks

DBA Team
EOF
fi
