#!/bin/sh

##Author : solomon Chigurupati
##version : 1.0

## usage : ./create_user_all_dbs.sh username password email_id


DATE=`date +"%Y%m%d_%H%M%S"`
export SCRIPT_PATH=/db/sw/oracle/scripts
MESG_LOG_FILE=$SCRIPT_PATH/tablespace_check.msg
MESG_BODY_FILE=$SCRIPT_PATH/tablespace.msg
export MAIL_LOG_DBA=`sh /db/sw/oracle/scripts/mail_log_to_dba.sh`
cp /dev/null $MESG_LOG_FILE

cd /home/oracle
ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM=vt100;export ORACLE_TERM
ORACLE_SID=$DBNAME;export ORACLE_SID
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH
cd $SCRIPT_PATH

echo "----------------------------------Production Databases----------------------------------------------------------" >> $MESG_LOG_FILE

for SID in prod kilo golf pcprod pcint bcprod cmprod logical_prod logical_kilo logical_golf bclogical_bcprod bclogical_cmprod cogprod
do

export ORACLE_SID="$SID"

export REMOTE_DATABASE="$SID"
touch $MESG_BODY_FILE
echo "date: $DATE" > $MESG_BODY_FILE
echo "instance: $ORACLE_SID" >> $MESG_BODY_FILE
touch $MESG_LOG_FILE

sqlplus -S /nolog <<!
    whenever oserror exit 12
    whenever sqlerror exit 12
    spool $SCRIPT_PATH/logs/dbconnect_${ORACLE_SID}_$DATE.out
    connect system/ClGOlymp1c5tm@${REMOTE_DATABASE}
    spool off
    set echo off verify off termout off feedback off
    set heading off escape on pagesize 0 linesize 80
    set serverout on size 1000000 format wrapped
    spool $SCRIPT_PATH/logs/tablespace_${ORACLE_SID}_$DATE.out
    start $SCRIPT_PATH/tablespace_report.sql
!

if [ $? = 0 ]; then
 numlines=`cat $SCRIPT_PATH/logs/tablespace_${ORACLE_SID}_$DATE.out | wc -l`
   if [ "$numlines" -gt 0 ]; then
        cat $MESG_BODY_FILE >> $MESG_LOG_FILE
        cat $SCRIPT_PATH/logs/tablespace_${ORACLE_SID}_$DATE.out >> $MESG_LOG_FILE
        echo " " >> $MESG_LOG_FILE
        echo "-------------------------------------------------------------------------------------" >> $MESG_LOG_FILE
        echo " " >> $MESG_LOG_FILE
   fi
else
 numlines1=`cat $SCRIPT_PATH/logs/dbconnect_${ORACLE_SID}_$DATE.out | wc -l`
   if [ "$numlines1" -gt 0 ]; then
        cat $MESG_BODY_FILE >> $MESG_LOG_FILE
        echo "Not table to connect to $ORACLE_SID database. Please verify below errors !!" >> $MESG_LOG_FILE
        cat $SCRIPT_PATH/logs/dbconnect_${ORACLE_SID}_$DATE.out | grep -i "ORA-" >> $MESG_LOG_FILE
        echo " " >> $MESG_LOG_FILE
        echo "-------------------------------------------------------------------------------------" >> $MESG_LOG_FILE
        echo " " >> $MESG_LOG_FILE
  fi
fi
done

lines=`cat $MESG_LOG_FILE | wc -l`

if [ "$lines" -gt 2 ]; then
      mailx -s "Tablespace Report in all PRODUCTION DB's" $MAIL_LOG_DBA <$MESG_LOG_FILE
else
      echo "All the tablespaces are above threshold. No action needed." > $MESG_LOG_FILE
#      mailx -s "Tablespace Report in all PRODUCTION DB's"  $MAIL_LOG_DBA <$MESG_LOG_FILE
fi

#      mailx -s "Tablespace Report in all PRODUCTION DB's" schigurupati@ciginsurance.com <$MESG_LOG_FILE


/bin/rm $SCRIPT_PATH/logs/tablespace_*.out
/bin/rm $SCRIPT_PATH/tablespace_check.msg
/bin/rm $MESG_BODY_FILE
/bin/rm  $SCRIPT_PATH/logs/dbconnect_*.out

