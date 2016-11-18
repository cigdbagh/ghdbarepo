#!/bin/sh
# Name     :  expdp_approd.sh
# Author   :  Ganga Pisari 
# created  :  11/03/16

DBNAME=approd1;export DBNAME
ORACLE_SID=${DBNAME};export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

LOG_PATH="/db/sw/oracle/backup/logs";export LOG_PATH
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
PWD=`sh ${PWD_PATH}/getpopn1.sh`

DBNAME=${ORACLE_SID}
SCHEMA="system"
CURR_DATE=`date "+%x %X"`

rm -rf /rman/oracle/approd/export.dir/*.dmp

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

expdp DIRECTORY=EXP_FULL_DIR dumpfile=EXP_FULL_DIR:expdp_approd_full_%U.dmp LOGFILE=EXP_LOG_DIR:expdp_${DBNAME}.log schemas=APADMIN  parallel=6 FILESIZE=4024M userid=${SCHEMA}/${PWD}@${DBNAME} flashback_scn=${F_SCNUM} cluster=no

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_DBAGRP=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_TO_USER=`sh ${PWD_PATH}/mail_log_to_dba.sh`

MAIL_SUBJ="Do Not Page - Error in expdp_${DBNAME}_${SCHEMA}"
MAIL_BODY="Check ${LOG_PATH}/expdp_${DBNAME}_${SCHEMA}.log"

LOGFILE="${LOG_PATH}/expdp_${DBNAME}.log"
TXTFILE="${LOG_PATH}/page_expdp_${DBNAME}_full.txt"

pg $LOGFILE|grep "successfully completed" > $TXTFILE
         STRING1=`pg $TXTFILE|awk '{ print $3 " " $4 }'`
         if [ "${STRING1}" != "successfully completed" ]
            then
      mailx -s "${MAIL_SUBJ}" "${MAIL_LOG_TO_DBA}" <<EOF
"${MAIL_BODY}"
EOF
      touch ${LOG_PATH}/expdp_err.dat
      exit 1
 fi
