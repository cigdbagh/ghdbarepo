#!/bin/sh
# Name     :  ctl_backup_main.sh
# Author   :  Raman Paul 
# created  :  01/23/07
# Modified :  

SCRIPT_PATH="/db/sw/oracle/scripts/db_maint/configfile_backup";export SCRIPT_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getdopnsys1.sh`

sh $SCRIPT_PATH/controlfile_backup.sh cigprod  
#sh $SCRIPT_PATH/controlfile_backup.sh prod  
#sh $SCRIPT_PATH/controlfile_backup_kilo.sh kilo  
##*##sh $SCRIPT_PATH/controlfile_backup.sh oscar  

