#!/bin/sh
# Name     :  pin_prod_pkg_keep.sh
# Author   :  Shashi Pavan 
# created  :  04/08/2002
# Desc     :  This procedure will be run daily for OLTP performance.
#             This procedure/shell script will be modified as the pkg/proc size is greater than 10000 shared_memory bytes.
#             Inorder to modify this shell ,need to run pin.sql script.
# Modified :  05/19/03 - Sasi Sivadasan - SP_GOOD_DRIVER procedure removed from the scripts due that object become obsolete. 
#          :  04/26/04 - Marimer P      - Added new packages for 5.1., removed sp_insert_diary, sp_insertnote,
#          :                              sp_insertdiary,pkg_prempymtplan (objects were dropped for 5.1)
#          :  02/01/05 - Sasi Sivadasan - Scripts are rewrote to include scripting standards. 
#                                         Variables, error checking, logging, desc, password hiding and mailing the logs etc
#                                         are included. 
#                                         Passwords are removed from scripts for better security and new method introduced. 
#          :  11/10/05 - Sasi Sivadasan - ktrivedi@ciginsurance.com rpaul@ciginsurance.com added in script
#	   :  03/20/06 - kavita		- MAIL_LOG_TO_DBA & changed the path from 8.1.6 - 10.2.0
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx 

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME="/u01/app/oracle/product/12.1.0.2/db_1";export ORACLE_HOME
#ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH

PWD=`sh ${PWD_PATH}/getdopnsys1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="sys"
RM="/bin/rm"
CURR_DATE=`date "+%x %X"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

LOG_FILE="${LOG_PATH}"/"pin_pkg_keep_${SCHEMA}_${DBNAME}.lst"
TXT_FILE="${LOG_PATH}"/"pin_pkg_keep_${SCHEMA}_${DBNAME}.txt"
ERR_FILE="${LOG_PATH}"/"pin_pkg_keep_${SCHEMA}_${DBNAME}.err"
RM_LOG="${LOG_PATH}"/"rm_pin_pkg_keep_${S_HOST}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dbagrp.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Weekly Scripts (${U_S_HOST}): ERROR on pin_pkg_keep in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Weekly Scripts (${U_S_HOST}): Pin_pkg_keep completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Weekly Scripts (${U_S_HOST}): ERROR in removing pin_pkg_keep logs."

if [ -f ${LOG_FILE} ]
   then
   $RM ${LOG_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME} as sysdba
spool ${LOG_FILE}
prompt Starting PIN_PROD_PKG_KEEP ... 
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;

exec dbms_shared_pool.keep ('PKG_EXTEND_POLICY','P');
exec dbms_shared_pool.keep ('PKG_POST_CHECKS','P');
exec dbms_shared_pool.keep ('PKG_DF_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_PRINT_CLAIM_ACORD','P');
exec dbms_shared_pool.keep ('PKG_CLAIMANT_COV_UPDATE','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_FARM_CREDITS','P');
exec dbms_shared_pool.keep ('PKG_PA_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_RP','P');
exec dbms_shared_pool.keep ('PKG_PA_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_FARM_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_FARM_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_PRINT_NON_DRIVER_NOTICES','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_REVERSE','P');
exec dbms_shared_pool.keep ('UTL_FILE','P');
exec dbms_shared_pool.keep ('PKG_BOP_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_WRAP_TEXT','P');
exec dbms_shared_pool.keep ('PKG_PA_RATES','P');
exec dbms_shared_pool.keep ('PKG_BOP_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_DRAFT','P');
exec dbms_shared_pool.keep ('PKG_UP_NOTICE','P');
exec dbms_shared_pool.keep ('PKG_CLAIMANT_TRANS_CEDED','P');
exec dbms_shared_pool.keep ('PKG_PA_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_FARM_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_BILLING','P');
exec dbms_shared_pool.keep ('PKG_HO_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_FARM_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_HO_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_CREDITS_WORKSHEET','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_HO_REWRITE_TO_POLICY','P');
exec dbms_shared_pool.keep ('PKG_HO_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_DF_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_RPS','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_BOP_RATE','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_VIN','P');
exec dbms_shared_pool.keep ('PKG_ADDRESS','P');
exec dbms_shared_pool.keep ('SYS_STUB_FOR_PURITY_ANALYSIS','P');
exec dbms_shared_pool.keep ('PKG_EXTEND_POLICY','P');
exec dbms_shared_pool.keep ('PKG_POST_CHECKS','P');
exec dbms_shared_pool.keep ('PKG_DF_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_MVR','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_FARM_CREDITS','P');
exec dbms_shared_pool.keep ('PKG_PA_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_PA_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_REVERSE','P');
exec dbms_shared_pool.keep ('SP_CHECK_PAYABLE_AUDIT','P');
exec dbms_shared_pool.keep ('PKG_PRINT_NON_DRIVER_NOTICES','P');
exec dbms_shared_pool.keep ('UTL_FILE','P');
exec dbms_shared_pool.keep ('PKG_BOP_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_PA_REVERSE','P');
exec dbms_shared_pool.keep ('SP_INSERT_LAYER_CONTRACT','P');
exec dbms_shared_pool.keep ('PKG_BOP_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_PA_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_FARM_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_HO_RATES','P');
exec dbms_shared_pool.keep ('PKG_CREDITS_WORKSHEET','P');
exec dbms_shared_pool.keep ('PKG_BOP_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_HO_REWRITE_TO_POLICY','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_FARM_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_RPS','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_ADDRESS','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_DEC','P');
exec dbms_shared_pool.keep ('PKG_FARM_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_MVR','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_NV_SUBMISSION','P');
exec dbms_shared_pool.keep ('PKG_BOP_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_FARM_RATE','P');
exec dbms_shared_pool.keep ('PKG_DF_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_FARM_RATE','P');
exec dbms_shared_pool.keep ('PKG_PRINT_CALLIGO_DEC','P');
exec dbms_shared_pool.keep ('PKG_PRINT_CALLIGO_BILLS','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_PA_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_BOP_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_BUILD_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_BOP_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_DF_REWRITE_POLICY','P');
exec dbms_shared_pool.keep ('PLITBLM','P');
exec dbms_shared_pool.keep ('PKG_NEW_SCANLINE','P');
exec dbms_shared_pool.keep ('PKG_HO_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_BOP_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_RATES','P');
exec dbms_shared_pool.keep ('PKG_PA_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_PREMIUM','P');
exec dbms_shared_pool.keep ('RETURN_UNIT_RECORDS','P');
exec dbms_shared_pool.keep ('PKG_BOP_CREDITS','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_DEC','P');
exec dbms_shared_pool.keep ('PKG_FARM_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_CLAIMANT_COV_UPDATE','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_DF_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_RP','P');
exec dbms_shared_pool.keep ('PKG_NV_SUBMISSION','P');
exec dbms_shared_pool.keep ('PKG_BOP_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_FARM_REWRITE','P');
exec dbms_shared_pool.keep ('DBMS_SPACE_ADMIN','P');
exec dbms_shared_pool.keep ('PKG_FARM_RATE','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_FARM_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_FARM_RATE','P');
exec dbms_shared_pool.keep ('PKG_FARM_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_DRAFT','P');
exec dbms_shared_pool.keep ('PKG_UP_NOTICE','P');
exec dbms_shared_pool.keep ('PKG_CLAIMANT_TRANS_CEDED','P');
exec dbms_shared_pool.keep ('PKG_BOP_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_BILLING','P');
exec dbms_shared_pool.keep ('PKG_DF_REWRITE_POLICY','P');
exec dbms_shared_pool.keep ('PKG_NEW_SCANLINE','P');
exec dbms_shared_pool.keep ('PKG_HO_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_FARM_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_HO_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_PA_GLOBAL_RATE','P');
exec dbms_shared_pool.keep ('PKG_FARM_REVERSE','P');
exec dbms_shared_pool.keep ('PKG_DF_GEN_DEC','P');
exec dbms_shared_pool.keep ('PKG_BOP_RATE','P');
exec dbms_shared_pool.keep ('PKG_PXC_POLICY_PREMIUM','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_PREMIUM','P');
exec dbms_shared_pool.keep ('RETURN_UNIT_RECORDS','P');
exec dbms_shared_pool.keep ('PKG_BOP_CREDITS','P');
exec dbms_shared_pool.keep ('PKG_VIN','P');
exec dbms_shared_pool.keep ('SP_STATUS_HISTORY','P');
exec dbms_shared_pool.keep ('SP_RESET_REQUEST_TABLE_STATUS','P');
exec dbms_shared_pool.keep ('DBMS_DESCRIBE','P');
exec dbms_shared_pool.keep ('DBMS_SQL','P');
exec dbms_shared_pool.keep ('SP_CLAIM_OC','P');
exec dbms_shared_pool.keep ('STANDARD','P');
exec dbms_shared_pool.keep ('DBMS_SYS_SQL','P');
exec dbms_shared_pool.keep ('DBMS_STANDARD','P');
exec dbms_shared_pool.keep ('PKG_DF_RATES','P');
exec dbms_shared_pool.keep ('SP_9221','P');
exec dbms_shared_pool.keep ('PKG_CLAIM_OC','P');
exec dbms_shared_pool.keep ('SP_9221_SUMMARY','P');
exec dbms_shared_pool.keep ('DBMS_OUTPUT','P');
exec dbms_shared_pool.keep ('STANDARD','P');
exec dbms_shared_pool.keep ('DBMS_UTILITY','P');
exec dbms_shared_pool.keep ('DBMS_SYS_SQL','P');
exec dbms_shared_pool.keep ('PKG_DF_RATES','P');
exec dbms_shared_pool.keep ('DBMS_APPLICATION_INFO','P');
exec dbms_shared_pool.keep ('PKG_PREM_LOSS_HIST','P');
exec dbms_shared_pool.keep ('SP_PRINT_PAF_BY_CLAIM','P');
exec dbms_shared_pool.keep ('PKG_CIG_UTILITIES','P');
exec dbms_shared_pool.keep ('PKG_PAF_LETTER','P');
exec dbms_shared_pool.keep ('PKG_ADMIN_AUDIT','P');
exec dbms_shared_pool.keep ('PKG_POLICY','P');
exec dbms_shared_pool.keep ('PKG_BILLING_CONSTANTS','P');
exec dbms_shared_pool.keep ('PKG_ACCOUNT','P');
exec dbms_shared_pool.keep ('PKG_TRACE','P');
exec dbms_shared_pool.keep ('PKG_PAYMENT','P');
exec dbms_shared_pool.keep ('PKG_CONTROL','P');
exec dbms_shared_pool.keep ('PKG_NOTICES','P');
exec dbms_shared_pool.keep ('PKG_PXC_RATES','P');
exec dbms_shared_pool.keep ('PKG_ADMIN','P');
exec dbms_shared_pool.keep ('PKG_ACCOUNT_BILL','P');
exec dbms_shared_pool.keep ('PKG_BILLING_INTERFACE','P');
exec dbms_shared_pool.keep ('PKG_EFT','P');
exec dbms_shared_pool.keep ('PKG_AGENCY','P');
exec dbms_shared_pool.keep ('PG_CLAIMANT','P');
exec dbms_shared_pool.keep ('PG_COLSUMMARY','P');
exec dbms_shared_pool.keep ('PG_CRU','P');
exec dbms_shared_pool.keep ('PG_DASHBOARD','P');
exec dbms_shared_pool.keep ('PG_CMS_DIARY','P');
exec dbms_shared_pool.keep ('PG_FASTTRACK','P');
exec dbms_shared_pool.keep ('PG_FENCEWORKSHEET','P');
exec dbms_shared_pool.keep ('PG_LITIGATION','P');
exec dbms_shared_pool.keep ('PG_NOTE','P');
exec dbms_shared_pool.keep ('PG_PARTY','P');
exec dbms_shared_pool.keep ('PG_POLICY_INFO','P');
exec dbms_shared_pool.keep ('PG_SALVAGE','P');
exec dbms_shared_pool.keep ('PKG_GLOBAL_REWRITE','P');
exec dbms_shared_pool.keep ('PKG_CCPYMT','P');
exec dbms_shared_pool.keep ('PG_LOOKUP_VALUE','P');
exec dbms_shared_pool.keep ('PG_PARAM_VALUES','P');
exec dbms_shared_pool.keep ('PG_AGENCY','P');
exec dbms_shared_pool.keep ('PG_AUTO_COVERAGE','P');
exec dbms_shared_pool.keep ('PG_ADDL_INTEREST','P');
exec dbms_shared_pool.keep ('PG_DRIVER','P');
exec dbms_shared_pool.keep ('PG_POLICY','P');
exec dbms_shared_pool.keep ('PG_NAMED_INSURED','P');
exec dbms_shared_pool.keep ('PG_VEHICLE','P');
exec dbms_shared_pool.keep ('PG_INSURED','P');
exec dbms_shared_pool.keep ('PG_VEHICLE_DRIVER_LINK','P');
exec dbms_shared_pool.keep ('PG_DEC_POLICY','P');
exec dbms_shared_pool.keep ('PG_DEC_NON_DRIVER','P');
exec dbms_shared_pool.keep ('PG_DEC_VEHICLE','P');
exec dbms_shared_pool.keep ('PG_DEC_DRIVER','P');
exec dbms_shared_pool.keep ('PG_CREDIT_SCORE','P');
exec dbms_shared_pool.keep ('PG_ADDR','P');
exec dbms_shared_pool.keep ('PG_DRIVER_POINTS','P');
exec dbms_shared_pool.keep ('PG_WRITING_COMPANY','P');
exec dbms_shared_pool.keep ('PG_DEC_AUTO_COVERAGE','P');
exec dbms_shared_pool.keep ('PG_DEC_ADDL_INTEREST','P');
exec dbms_shared_pool.keep ('PG_DEC_DRIVER_POINTS','P');
exec dbms_shared_pool.keep ('PG_DEC_VEHICLE_DRIVER_LINK','P');
exec dbms_shared_pool.keep ('PG_FINANCIAL_INSTITUTION','P');
exec dbms_shared_pool.keep ('PKG_AQS_INFORMATION_REQUEST','P');
exec dbms_shared_pool.keep ('PKG_ACCOUNT_UTILS','P');
exec dbms_shared_pool.keep ('CIGADMIN.PG_DEC_ADDL_EQMT','P');
exec dbms_shared_pool.keep ('PG_DOCUMENT_CACHE','P');
exec dbms_shared_pool.keep ('CIGADMIN.PG_ENDORSE_QUOTE_INFO','P');
exec dbms_shared_pool.keep ('PG_DOC_CACHE_VERSION','P');
exec dbms_shared_pool.keep ('PG_ADJUSTER_ASSIGNMENT','P');
exec dbms_shared_pool.keep ('PG_BIEVALUATION','P');
exec dbms_shared_pool.keep ('PG_CAUSELIST','P');
exec dbms_shared_pool.keep ('PG_CHECK_INCURREDLOSS','P');
exec dbms_shared_pool.keep ('PG_CLAIM_COVERAGE','P');
exec dbms_shared_pool.keep ('PG_CLAIM_INFO','P');
exec dbms_shared_pool.keep ('PKG_COMMERCIAL_UMBRELLA_RATING','P');
exec dbms_shared_pool.keep ('PG_SIU','P');
exec dbms_shared_pool.keep ('PG_SUBROGATION','P');
exec dbms_shared_pool.keep ('PG_USER_PROFILE','P');
exec dbms_shared_pool.keep ('PG_VENDOR','P');
exec dbms_shared_pool.keep ('PG_ZIPTOTAX','P');
exec dbms_shared_pool.keep ('PKG_WEBAPP_UTILITIES','P');
exec dbms_shared_pool.keep ('PKG_WEBAPP_GLOBAL','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_POLICY','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_PROPERTY','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_SUPPL','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_AUTO','P');
exec dbms_shared_pool.keep ('PKG_WEBAPP_MAIN_POLICY_SEARCH','P');
exec dbms_shared_pool.keep ('PKG_WEB_COMMON','P');
exec dbms_shared_pool.keep ('PKG_WEBAPP_FUNCTIONS','P');
exec dbms_shared_pool.keep ('PG_APP_HO_FARM_SUPP','P');
exec dbms_shared_pool.keep ('PG_APP_HO_HORSE_SUPP','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_GUNSUPP','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_HOMEBUS','P');
exec dbms_shared_pool.keep ('PKG_WEBAPPL_WATERCRAFT_SUPPL','P');
exec dbms_shared_pool.keep ('PG_WEBAPPL_RATING','P');
exec dbms_shared_pool.keep ('PG_WEBAPPL_FACTOR_VALUES','P');
exec dbms_shared_pool.keep ('PG_WEBAPPL_VEHICLE','P');
exec dbms_shared_pool.keep ('PKG_WEBAPP_VIN','P');
exec dbms_shared_pool.keep ('PG_WEBAPPL_DRIVER_POINTS','P');
exec dbms_shared_pool.keep ('PG_APP_DATA_VERSION','P');
exec dbms_shared_pool.keep ('PG_APP_HO_WOOD_STOVE_SUPP2','P');
exec dbms_shared_pool.keep ('PG_WEBAPP_POLICY_SEARCH','P');
exec dbms_shared_pool.keep ('PG_WEBAPPL_COPY_QUOTE','P');
exec dbms_shared_pool.keep ('PKG_ONLINE_END_AUTO_POLICY','P');
exec dbms_shared_pool.keep ('AGENCY_TMP.PKG_ONLINE_END_AUTO_BATCH','P');
exec dbms_shared_pool.keep ('AGENCY_TMP.PKG_WEB_ONLINE_RPT','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_APP_DATA_VERSION_ENDORSE','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_DEC_DRIVER_SUPPLEMENT','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_DEC_VDL_SUPPLEMENT','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_DEC_VEHICLE_SUPPLEMENT','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_WENDORSE_ADMIN_GET','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_WENDORSE_ADMIN_PUT','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_WENDORSE_RATING','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_WEBAPP_POLICY_SEARCH_WEND','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_WENDORSE_COMMON','P');
exec dbms_shared_pool.keep ('WENDORSE.PG_DEC_ADDL_EQMT','P');
exec dbms_shared_pool.keep ('PG_DEC_ADDL_INTEREST','P');
exec dbms_shared_pool.keep ('PG_DEC_AUTO_COVERAGE','P');
exec dbms_shared_pool.keep ('PG_DEC_DRIVER','P');
exec dbms_shared_pool.keep ('PG_DEC_DRIVER_POINTS','P');
exec dbms_shared_pool.keep ('PG_DEC_NON_DRIVER','P');
exec dbms_shared_pool.keep ('PG_DEC_POLICY','P');
exec dbms_shared_pool.keep ('PG_DEC_VEHICLE','P');
exec dbms_shared_pool.keep ('PG_DEC_VEHICLE_DRIVER_LINK','P');
--exec dbms_shared_pool.keep ('DBMS_CSX_ADMIN','P');

set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt PIN_PROD_PKG_KEEP complete.
spool off;
END_SQL

if [ -f ${ERR_FILE} ]
   then
   $RM ${ERR_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi
if [ -f ${TXT_FILE} ]
   then
   $RM ${TXT_FILE} > ${RM_LOG}
   STATUS="$?"
   if [ "${STATUS}" != 0 ]; then
      mailx -s "${RM_ERR}" "${MAIL_LOG_TO_DBA}" < "${RM_LOG}"
      exit 1
   fi
fi

pg ${LOG_FILE}|grep ORA- > ${ERR_FILE}
pg ${ERR_FILE}|egrep -vi 'ORA-00000|ORA-00000' > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
   BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
   if [ $BY_CNT != 0 ]
      then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBA}" < "${LOG_FILE}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${LOG_FILE}"
      exit 1
   fi
fi

