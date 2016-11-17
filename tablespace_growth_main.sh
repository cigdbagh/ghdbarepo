#!/bin/sh
# Name     :  tablespace_growth_main.sh 
# Author   :  Harpreet Singh 
# created  :  05/27/08
# Desc	   :  This is the main script to execute tablespace_growth.sh script
# Modified :  
#----------------------------------------------------------------------
SCRIPT_PATH="/db/sw/oracle/11.1.0/db_1/scripts/db_maint/tablespace_growth";export SCRIPT_PATH
sh $SCRIPT_PATH/tablespace_growth.sh prod

