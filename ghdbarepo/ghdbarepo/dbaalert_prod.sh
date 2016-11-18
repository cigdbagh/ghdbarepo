#!/bin/sh
# Author   : Ramesh Kalyandurg 
# created  :  02/04/14

ORACLE_SID="prod";export ORACLE_SID
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
DBNAME=${ORACLE_SID}
PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH
SCR_PATH="/db/sw/oracle/scripts/db_maint";export SCR_PATH
DIR="/db/sw/oracle/scripts/db_maint";export DIR
CURR_DATE=`date`
LOGFILE="$DIR/dbaalert_$ORACLE_SID.log"

MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`
MAIL_LOG_SUB="The DBA alert report is generated for ${ORACLE_SID} database on ${CURR_DATE}."
rm ${SCR_PATH}/dbaalert_$ORACLE_SID.log

SCHEMA="dbmaint"
PWD=`sh ${PWD_PATH}/getpopn1.sh`

sqlplus -S << END_SQL
${SCHEMA}/${PWD}@${DBNAME}
spool ${SCR_PATH}/dbaalert_$ORACLE_SID.log
@${SCR_PATH}/dbaalert_$ORACLE_SID.sql
spool off;
END_SQL

if [ -f $DIR/dbaalert_$ORACLE_SID.log ]
  then
mailx -s "$MAIL_LOG_SUB" "$MAIL_LOG_TO_DBA" < "$LOGFILE"
exit 1
fi
