# ! /usr/bin/sh
# Name        :  run_auto_email.sh 
# Author      :  Sasibhushan Sivasasan
# Description :  This script used to run execute_pkg_auto_email.sh and no_email_report.sh with parameters. 
#                Usage of the script is 'sh run_auto_email.sh'.
# Notes       :  This script can run from oracle or root user.
# Created     :  03/30/03
# Modified    :  06/24/03 - Sasi - Added documentaion
#                07/28/03 - Sasi - Description modified
#                02/18/05 - Sasi Sivadasan - Passwords are removed from scripts for better security and new method introduced.
#                00/00/00 - xxxx - xxxxxxxxxxxxxxxxxx

SCR_PATH="/db/sw/oracle/scripts/db_maint/auto_email";export SCR_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getpopn1.sh`

sh $SCR_PATH/execute_pkg_auto_email.sh prod dbmaint ${PWD}

sh $SCR_PATH/no_email_report.sh prod dbmaint ${PWD}
