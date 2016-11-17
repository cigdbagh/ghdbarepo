#!/bin/sh
# Name     :  analyze_schema_main.sh
# Author   :  Sasibhushan Sivasasan
# created  :  08/03/06
# Modified :  

SCRIPT_PATH="/db/sw/oracle/scripts/db_maint/analyze_db";export SCRIPT_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getpopn1.sh`
PWD_IPUB="ipubPpw0d$"

sh $SCRIPT_PATH/analyze_schema.sh prod cigadmin ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod whouse ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod agency_tmp ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod agency ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod webapp ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod pubrequest ${PWD} 
sh $SCRIPT_PATH/analyze_schema.sh prod wendorse ${PWD} 
sh $SCRIPT_PATH/analyze_schema_ipub.sh kilo idm62 ${PWD_IPUB} 
sh $SCRIPT_PATH/analyze_schema_ipub.sh kilo pubdomain ${PWD_IPUB} 
sh $SCRIPT_PATH/analyze_schema_ipub.sh kilo pubconsole ${PWD_IPUB} 

