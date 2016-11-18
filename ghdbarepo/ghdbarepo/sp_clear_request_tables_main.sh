#!/bin/sh
# Name     :  sp_clear_request_tables_main.sh
# Author   :  Harpreet Singh 
# Created  :  03/11/2010
# Desc     :  This particular shell script is used to run data fix procedure sp_clear_request_table. 
#             The ORACLE_SID and p_path should be modified to the database which these packages are run across.
#             This script runs from Monday-Friday at 18:10
###################################
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
sh ${SCR_PATH}/sp_clear_request_tables.sh prod cigadmin sp_clear_req_table_eliens 
sh ${SCR_PATH}/sp_clear_request_tables.sh prod pubrequest sp_clear_request_table

