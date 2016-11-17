#!/bin/sh
# Author   :  Ramesh 
# created  :  06/08/16

ERRMSG="Usage: `basename $0` <dbname>"

if [ "$1" ]
  then DBNAME=$1
else echo $ERRMSG
  exit
fi

ORACLE_SID=${DBNAME};export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

SCHEMA="system"
PWD=`sh ${PWD_PATH}/getpopn1.sh`
U_DBNAME=`echo ${DBNAME} | tr "[a-z]" "[A-Z]"`

p_path="/db/sw/oracle/scripts/db_maint";export p_path
LOG_PATH="/db/sw/oracle/scripts/db_maint/logs";export LOG_PATH

t=`date "+%D %T"`
LOGFILE="${LOG_PATH}/dbaalert_${DBNAME}.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_SUB="The DBA alert report is generated for ${U_DBNAME} database on $t."

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${LOGFILE}
@$p_path/bc_stats.sql
spool off;
END_SQL

if [ -f ${LOGFILE} ]
  then
mailx -s "$MAIL_LOG_SUB" "$MAIL_LOG_TO_DBA" < "$LOGFILE"
exit 1
fi
