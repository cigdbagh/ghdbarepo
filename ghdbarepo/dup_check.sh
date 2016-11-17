#!/bin/sh
# Name     :  dup_check.sh
# Author   :  Sasi Sivadasan
# created  :  02/03/05
# Desc     :  This particular shell script is used to check the duplicate policy_search_nbr in policy table.
#             This script runs from Monday-Friday at 07:25 & 16:45. This script calls dup_check_cigadmin.sh to check
#             duplicate policy_search_nbr in CIGADMIN schema and dup_check_agency.sh for the AGENCY schema.
#
#	   :  03/20/06 - kavita		- changed the path from 8.1.6 - 11.1.0/db_1
# Modified :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH

sh ${SCR_PATH}/"dup_check_cigadmin.sh"
sh ${SCR_PATH}/"dup_check_agency_tmp.sh"
