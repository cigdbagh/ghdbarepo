# ! /usr/bin/sh
# Name        :  alert_log_maint_hp1_main.sh - Script used to run alert_log_maint.sh 
# Author      :  Sasibhushan Sivasasan
# Description :  This is a script can be use to run alert_log_main.sh. Alert.log maintenanece of many databases#                can be done using this script. Usage of the script is 'sh alert_log_maint.sh'. This script
#                created for the databases in hp1 server. 
# Notes       :  This script can use to schedule every month to move the alert.log from oracle or root user.
# Created     :  02/06/03
# Modified    :  02/07/03 - Sasi - Added description
#                02/07/03 - Sasi -
#		 03/24/06 - kavita - Changed path from 8.1.6 - 11.1.0/db_1

DIR1="/db/sw/oracle/scripts/db_maint/logfile_maint"

sh $DIR1/alert_log_maint.sh prod
