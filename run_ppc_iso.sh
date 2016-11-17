#!/bin/sh
# Name     :  run_ppc_iso.sh
# Author   :  Ramesh
# Created  :  04/28/15
#          :  00/00/00 - xxxx xxxxxxxxx - xxxxxxxxxx

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES";export SCR_PATH
LOG_PATH="/db/sw/oracle/scripts/ORACLE/DATA_FIXES/logs";export LOG_PATH
SOURCE_DIR="/db/data/a3/oracle/${ORACLE_SID}/interfaces"

PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
RM="/bin/rm"
PG="/bin/pg"
MV="/bin/mv"
CURR_DATE=`date "+%x %X"`
CURR_D=`date +"%m%d%y"`
S_HOST=`hostname`
U_S_HOST=`echo ${S_HOST} | tr "[a-z]" "[A-Z]"`
U_DBNAME=`echo ${ORACLE_SID} | tr "[a-z]" "[A-Z]"`
U_SCHEMA=`echo ${SCHEMA} | tr "[a-z]" "[A-Z]"`

T_HOST=`hostname`
U_T_HOST=`echo $T_HOST | tr "[a-z]" "[A-Z]"`
COMM_LOGFILE="$LOG_PATH"/"iso_${T_HOST}.log"
LOG_FILE=${LOG_PATH}/"iso.log"
TXT_FILE=${LOG_PATH}/"iso.txt"
TXTFILE1B=${LOG_PATH}/"iso.txt"
ERRFILE=${LOG_PATH}/"iso.dat"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
#MAIL_LOG_TO_DBA="rkalyandrug@ciginsurance.com"
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
#MAIL_LOG_TO_DBAGRP='rkalyandrug@ciginsurance.com'
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA} rkalyadrug@ciginsurance.com  agrover@ciginsurance.com  SRajagopal@ciginsurance.com "
#MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"

MAIL_LOG_SUB1="Daily Data Fixes (${U_S_HOST}): ERROR on PKG_PPC_ISO in ${U_SCHEMA} of ${U_DBNAME}"
MAIL_LOG_SUB2="Daily Data Fixes (${U_S_HOST}): PKG_PPC_ISO completed in ${U_SCHEMA} of ${U_DBNAME}"
RM_ERR="Daily Scripts (${U_S_HOST}): ERROR in removing PKG_PPC_ISO logs."
$RM ${COMM_LOGFILE}

cd $SOURCE_DIR
echo $SOURCE_DIR
pwd
CURR_DATE=`date "+%x %X"`
echo "Starting PPC file processing.... " > $COMM_LOGFILE
echo " " >> $COMM_LOGFILE
echo $FILE
echo "	" >> $COMM_LOGFILE
##*##ls -ltr PPPCIGR01*.txt | awk '{ print$9}'
for FILE in `/bin/ls -altr PPPCIGR01*.txt | awk '{ print$9}'` 
##for file in PPPCIGR01-*.txt;
do
CURR_DATE=`date "+%x %X"`
echo "	" >> $COMM_LOGFILE

#--- Call db name ,shema and password  SQL block for package
PWD=`sh ${PWD_PATH}/getpopn1.sh`
DBNAME=${ORACLE_SID}
SCHEMA="cigadmin"
#--- Add SQL block for package
sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOG_FILE}
prompt Starting BATCH PROCESSING FOR PPC ISO...
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') START_DATE from dual;
show user;
select name database from v\$pdbs;
select name instance_name from cig_instance;
set time on timing on;
select 'PL/SQL procedure successfully completed.' from dual;
execute PKG_PPC_ISO.SP_PPC_RESPONSE ('$FILE');
set time off timing off;
SELECT TO_CHAR(sysdate,'MM/DD/YY HH24:MI:SS') END_DATE from dual;
prompt BATCH PROCESSING FOR PPC ISO complete.
spool off;
END_SQL
$PG ${LOG_FILE} >> ${COMM_LOGFILE}
$MV $FILE $CURR_D$FILE
done
#---- Check error handling --

pg ${COMM_LOGFILE}|grep ORA- > ${TXT_FILE}
if [ -f ${TXT_FILE} ]
   then
       BY_CNT=`ls -ltr ${TXT_FILE}|awk '{ print $5 }'`
       if [ ${BY_CNT} != 0 ]; then
      mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_DBAGRP}" < "${COMM_LOGFILE}"
     # mailx -s "${MAIL_LOG_SUB1}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
      exit 1
   else
      mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_USER}" < "${COMM_LOGFILE}"
      #mailx -s "${MAIL_LOG_SUB2}" "${MAIL_LOG_TO_DBAGRP}" < "${COMM_LOGFILE}"
      exit 1
   fi
fi
