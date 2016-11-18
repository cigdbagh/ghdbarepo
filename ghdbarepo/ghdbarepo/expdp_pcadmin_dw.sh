#!/bin/sh
# Name     :  exp_dw_pcprod.sh
# Author   :  Ramesh  kalyandrug 
# created  :  04/20/16
DBNAME=pcprod1;export DBNAME
ORACLE_SID=${DBNAME};export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME 
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

#LOG_PATH="/db/sw/oracle/backup/logs";export LOG_PATH
LOG_PATH="/backup/oracle/pc/export.dir";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
mv /backup/oracle/pc/export.dir/pcadmin.dmp /backup/oracle/pc/old
DBNAME=${ORACLE_SID}
SCHEMA="system"
PWD=`sh ${PWD_PATH}/getpopn1.sh`
###-----------------Get the Scn Number ---------------------
getfscn=`sqlplus -s <<END
system/${PWD}@${DBNAME}
set heading off
--set pagesize 0
set tab off
col get_system_change_number for 9999999999999;
select dbms_flashback.get_system_change_number from dual;
END`
for item in ${getfscn}
do
F_SCNUM=${item}
echo $F_SCNUM
done
export F_SCNUM
###-----------------Got the Scn Number ---------------------

CURR_DATE=`date "+%x %X"`
PARAFILE_PATH="/db/sw/oracle/backup/refresh_admin_tables"; export PARAFILE_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
mv /backup/oracle/pc/export.dir/pcadmindw.dmp /backup/oracle/pc/old
DBNAME=${ORACLE_SID}
SCHEMA1="pcadmin"
PWD=`sh ${PWD_PATH}/getpopn1.sh`
CURR_DATE=`date "+%x %X"`
expdp DIRECTORY=EXP_FULL dumpfile=EXP_FULL:pcadmindw.dmp LOGFILE=EXP_FULL:exp_${DBNAME}_pcadmindw.log  userid=${SCHEMA1}/cigpcmiracle@${DBNAME} parfile=${PARAFILE_PATH}/pcadmin_tables EXCLUDE=CONSTRAINT,GRANT,REF_CONSTRAINT,TRIGGER,INDEX
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER="${MAIL_LOG_TO_DBA}"
MAIL_SUBJ="Do Not Page - Error in expdp_${DBNAME}_${SCHEMA1}"
MAIL_SUBJ1="import completed succeusfully for DW in ${DBNAME}_${SCHEMA1}"
MAIL_BODY="Check ${LOG_PATH}/expdp_dw_${DBNAME}_${SCHEMA1}.log"
MAIL_BODY1="import succusfully completed on ${DBNAME}_dw_${SCHEMA1}"
LOGFILE="${LOG_PATH}/exp_${DBNAME}_pcadmindw.log"
TXTFILE="${LOG_PATH}/page_expdp_${DBNAME}_dw.txt"

pg $LOGFILE|grep "successfully completed" > $TXTFILE
         STRING1=`pg $TXTFILE|awk '{ print $3 " " $4 }'`
         if [ "${STRING1}" != "successfully completed" ]
            then
      mailx -s "${MAIL_SUBJ}" "${MAIL_LOG_TO_DBA}" <<EOF
"${MAIL_BODY}"
EOF
 fi

