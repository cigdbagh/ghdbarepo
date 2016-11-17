#!/bin/sh
# Name     :  analyze_table_stats_main.sh
# Author   :  Raman Paul 
# created  :  08/03/06
# Modified :  12/11/06 - Harpreet Singh - Removed passwords as parameters to scripts 

SCRIPT_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export SCRIPT_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

sh $SCRIPT_PATH/analyze_tables.sh prod cigadmin  
#sh $SCRIPT_PATH/analyze_tables.sh kilo pubconsole  
#sh $SCRIPT_PATH/analyze_tables.sh kilo pubdomain  
#sh $SCRIPT_PATH/analyze_tables.sh kilo idm62  

