!/bin/sh
# Author   :  Sasi Sivadasan
# created  :  10/08/04
# Modified :  10/20/04 - Sasi - New variables like DBNAME, SCHEMA, PASSWORD etc. added to globalize
#                             - the scripts. Rewrote the logic to improve the performance.
#          :  03/09/05 - Sasi Sivadasan - Passwords are removed from scripts for better security and new method introduced.
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

SCR_PATH="/db/sw/oracle/scripts/db_maint/db_monitor";export SCR_PATH
sh $SCR_PATH/logswitch.sh prod 
