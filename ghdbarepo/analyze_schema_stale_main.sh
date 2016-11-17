#!/bin/sh
# Name     :  analyze_schema_prod_stale_main.sh
# Author   :  Sasibhushan Sivasasan
# created  :  08/03/06
# Modified :  

SCRIPT_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export SCRIPT_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getpopn1.sh`

#sh $SCRIPT_PATH/analyze_schema_stale_stats.sh cohiba cigadmin 
sh $SCRIPT_PATH/analyze_schema_stale_stats.sh prod cigadmin 
sh $SCRIPT_PATH/analyze_schema_stale_stats.sh prod whouse 
sh $SCRIPT_PATH/analyze_schema_stale_stats.sh prod agency 
sh $SCRIPT_PATH/analyze_schema_stale_stats.sh prod agency_tmp 
sh $SCRIPT_PATH/analyze_schema_stale_stats.sh prod webapp 
#sh $SCRIPT_PATH/analyze_schema_stale_stats.sh kilo pubconsole 
#sh $SCRIPT_PATH/analyze_schema_stale_stats.sh kilo pubdomain 
#sh $SCRIPT_PATH/analyze_schema_stale_stats.sh kilo idm62 

###################################################
##Script added to export the statistics data     
##
sh $SCRIPT_PATH/exp_backup_stats_tab_main.sh
###################################################
