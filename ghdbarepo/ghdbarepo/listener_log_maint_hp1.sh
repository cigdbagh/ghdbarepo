# ! /bin/sh
# Name        :  listener_log_maint.sh
# Author      :  Sasibhushan Sivasasan
# Description :  This is a script can be use to move current listener.log of requesting host to logfile
#                backup directory. Usage of the script is sh listener_log_maint.sh.
# Notes       :  This script can schedule every month to move the listener.log in each server.
# Created     :  03/04/03
# Modified    :  03/04/03 - Sasi - Removed the comments
#                03/04/03 - Sasi -

ORACLE_HOME=`sh /db/sw/oracle/scripts/get_oracle_home.sh`;export ORACLE_HOME
ORACLE_TERM="vt100";export ORACLE_TERM
PATH=$ORACLE_HOME/bin:.:$PATH;export PATH

PWD_PATH="/db/sw/oracle/scripts";export PWD_PATH

CMP="/usr/bin/cmp"
LSNRCTL="/u01/app/oracle/product/11.2.0/db_1/bin/lsnrctl"
##*##LSNRCTL="/db/sw/oracle/bin/lsnrctl"
DATE=`date "+%m%d%y"`
TIME=`date "+%H%M%S"`
HOST=`hostname`

DIR1="/db/sw/oracle/scripts/db_maint/logfile_maint"
##*##DIR2="/db/sw/oracle/diag/tnslsnr/hp2/listener/trace"
DIR2="/u01/app/oracle/diag/tnslsnr/rh1/listener/trace"
DIR4="/db/sw/oracle/scripts/db_maint/logfile_maint/log"

# Logfiles_backup directory is different in each servers right now. Make this directory uniform after
# creating common directory in all servers. Until then DIR3 need to change according to servers.

# Logfiles_directory for HP1(new) server
# DIR3="/db/data/a26/oracle/logfiles_backup/network/log"    

# Logfiles_directory for HP2 server
##*##DIR3="/db/data/a26/oracle/logfiles_backup/network/log"    
DIR3="/db/data/a26/oracle/logfiles_backup/network/log"    

# Logfiles_directory for HP3 server
# DIR3="/db/log/oracle/logfiles_backup/network/log"    

# Logfiles_directory for HP4 server
# DIR3="/db/log/oracle/logfiles_backup/network/log"

# Testing directories
# DIR1="/db/sw/oracle/scripts/db_maint/logfile_maint"
# DIR2="/db/sw/oracle/scripts/db_maint/logfile_maint/network/log"
# DIR3="/db/sw/oracle/scripts/db_maint/logfile_maint/backup/network/log"
# DIR4="/db/sw/oracle/scripts/db_maint/logfile_maint/log"

FILE1="$DIR4"/"lsnr_status1.log"
FILE2="$DIR2"/"listener.log"
###FILE2="$DIR2"/"log.xml"
FILE3="$DIR4"/"lsnr_log_status_on.log"
FILE4="$DIR4"/"lsnr_log_status_off.log"
##FILE5="$DIR3"/"listener_${DATE}_${TIME}.log"
FILE5="$DIR3"/"listener_${DATE}_${TIME}.xml"
FILE6="$DIR4"/"lsnr_status2.log"

CMP_LOG="$DIR4"/"cmp.log"

###MAIL_LOG_TO_DBA="rpaul@ciginsurance.com"
MAIL_LOG_TO_DBA=`sh ${PWD_PATH}/mail_log_to_dba.sh`

MAIL_LOG_SUB1="Listener log maint: Listener is not running in $HOST. Check listener status."
MAIL_LOG_SUB2="Listener log maint: Error on checking listener status in $HOST."
MAIL_LOG_SUB3="Listener log maint: Listener log status is not ON in $HOST. Check listener log status."
MAIL_LOG_SUB4="Listener log maint: Error on checking listener log status in $HOST."
MAIL_LOG_SUB5="Listener log maint: Listener log status is not OFF in $HOST. Check listener log status."
MAIL_LOG_SUB6="Listener log maint: listener.log successfully deleted after backup in $HOST."
MAIL_LOG_SUB7="Listener log maint: listener.log with 0 bytes in $HOST."

CMP_ERR="Listener log maint: Error on logfile comparison $HOST"
CMP_SUCC="Listener log maint: Logfile comparison successfully completed in $HOST."


LSNR_STATUS=`$LSNRCTL << END_SQL
status
END_SQL`

echo $LSNR_STATUS|grep 'TNS-00511: No listener' > $FILE1

echo *-------------Starting A-----------------------
if [ -f $FILE1 ]
   then
   BY_CNT=`ls -ltr $FILE1|awk '{ print $5 }'`
   echo *--------------Starting B-----------------
   if [ $BY_CNT != 0 ]
       then
mailx -s "$MAIL_LOG_SUB1" "$MAIL_LOG_TO_DBA" < "$FILE1"
       exit 1
   else
       echo *--------------Starting C-----------------
       if [ -f $FILE2 ]
          then
          BY_CNT=`ls -ltr $FILE2|awk '{ print $5 }'`
          echo *--------------Starting D-----------------
          if [ $BY_CNT != 0 ]
             then
             # Check the log_status before changing the log_status
LSNR_LOG_STATUS=`$LSNRCTL << END_SQL
show log_status
END_SQL`
             echo $LSNR_LOG_STATUS|grep 'LISTENER parameter \"log_status\" set to ON' > $FILE3
             echo *--------------Starting E-----------------
             if [ -f $FILE3 ]
                then
	        BY_CNT=`ls -ltr $FILE3|awk '{ print $5 }'`
                echo *--------------Starting F-----------------
	        if [ $BY_CNT != 0 ]
		   then
####Uncomment after IP to hostname change in Listener 
		    RUN_CHECK=`cut -c281-321 $FILE3`
		   ##*## RUN_CHECK=`cut -c280-320 $FILE3`
		   #RUN_CHECK=`cut -c272-312 $FILE3`
		   echo $RUN_CHECK
                   echo *--------------Starting G-----------------
	           if [ "$RUN_CHECK" != "LISTENER parameter \"log_status\" set to ON" ]
               	      then
mailx -s "$MAIL_LOG_SUB3" "$MAIL_LOG_TO_DBA" < "$FILE3"
		      exit 1
        	   else
LSNR_LOG_STATUS=`$LSNRCTL << END_SQL
set log_status off
END_SQL`
                   fi
                   echo *--------------Ending G-----------------
                else  
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE3 file with zero bytes while checking listener log status.
EOF
		    exit 1
		fi
                echo *--------------Ending F-----------------
                # Check the log_status again before copy the listener.log
LSNR_LOG_STATUS=`$LSNRCTL << END_SQL
show log_status
END_SQL`
		echo $LSNR_LOG_STATUS
		echo $LSNR_LOG_STATUS|grep 'LISTENER parameter \"log_status\" set to OFF' > $FILE4
                echo *--------------Starting H-----------------
		if [ -f $FILE4 ]
		   then
		   BY_CNT=`ls -ltr $FILE4|awk '{ print $5 }'`
                   echo *--------------Starting I-----------------
	           if [ $BY_CNT != 0 ]
		      then
#####Uncomment after IP to hostname change in Listener 
	              RUN_CHECK=`cut -c281-322 $FILE4`
	             #RUN_CHECK=`cut -c272-313 $FILE4`
                      echo *--------------Starting J-----------------
		      echo "LISTENER parameter \"log_status\" set to OFF"
		      echo $RUN_CHECK
      		      if [ "$RUN_CHECK" != "LISTENER parameter \"log_status\" set to OFF" ]
		         then
			 echo "CAME BEFORE EMAIL"
mailx -s "$MAIL_LOG_SUB5" "$MAIL_LOG_TO_DBA" < "$FILE4"
			 exit 1
                      else
                          cp $FILE2 $FILE5
                          # echo "$CMP $FILE2 $FILE5" 
                          $CMP $FILE2 $FILE5 > $CMP_LOG
                          STATUS="$?"
                          echo *--------------Starting K-----------------
                          if [ "$STATUS" != 0 ]; then
                             echo "$CMP_ERR"
mailx -s "$CMP_ERR" "$MAIL_LOG_TO_DBA" < "$CMP_LOG"
                             exit 1
                          else
                              # echo "$CMP_SUCC"
                              cat /dev/null >$FILE2
LSNR_LOG_STATUS=`$LSNRCTL << END_SQL
set log_status on
END_SQL`
			  fi
                          echo *--------------Ending K-----------------
                       fi
                       echo *--------------Ending J-----------------
                    else
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE4 file with zero bytes while checking listener log status.
EOF
			exit 1
		    fi
                    echo *--------------Ending I-----------------
                else
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE4 file not found while checking listener log status.
EOF
		    exit 1
		fi
                echo *--------------Ending H-----------------
                # Check the log_status after seting the log_status
LSNR_LOG_STATUS=`$LSNRCTL << END_SQL
show log_status
END_SQL`
		echo $LSNR_LOG_STATUS
                echo $LSNR_LOG_STATUS|grep 'LISTENER parameter \"log_status\" set to ON' > $FILE3
                echo *--------------Starting L-----------------
                if [ -f $FILE3 ]
                   then
	           BY_CNT=`ls -ltr $FILE3|awk '{ print $5 }'`
                   echo *--------------Starting M-----------------
	           if [ $BY_CNT != 0 ]
		      then
#### Uncomment after IP to hostname change in Listener
		       RUN_CHECK=`cut -c281-321 $FILE3`
		      #RUN_CHECK=`cut -c272-312 $FILE3`
                      echo *--------------Starting N-----------------
	              if [ "$RUN_CHECK" != "LISTENER parameter \"log_status\" set to ON" ]
               	         then
mailx -s "$MAIL_LOG_SUB3" "$MAIL_LOG_TO_DBA" < "$FILE3"
		         exit 1
        	      else
LSNR_STATUS=`$LSNRCTL << END_SQL
status
END_SQL`
			  echo $LSNR_STATUS
                          echo $LSNR_STATUS|grep 'TNS-00511: No listener' > $FILE6
                          echo *--------------Starting O-----------------
                          if [ -f $FILE6 ]
                             then
                             BY_CNT=`ls -ltr $FILE6|awk '{ print $5 }'`
                             echo *--------------Starting P-----------------
                              if [ $BY_CNT = 0 ]
                                 then
mailx -s "$MAIL_LOG_SUB6" "$MAIL_LOG_TO_DBA" <<EOF
$FILE2 successfully moved after backup.
Please check $FILE5 for previous details.
EOF
                                  exit 1
                              else
mailx -s "$MAIL_LOG_SUB1" "$MAIL_LOG_TO_DBA" < "$FILE6"
                                    exit 1
                              fi
                              echo *--------------Ending P-----------------
                          else
mailx -s "$MAIL_LOG_SUB2" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE6 file not found while checking listener status.
EOF
		              exit 1
                          fi
                          echo *--------------Ending O-----------------
                      fi 
                      echo *--------------Ending N-----------------
                   else
		       # NEED TO THINK ABOUT THIS MESSAGE LOGIC
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE3 file with zero bytes while checking listener log status.
EOF
		       exit 1
                   fi
                   echo *--------------Ending M-----------------
                else
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE3 file not found while checking listener log status.
EOF
		    exit 1
                fi
                echo *--------------Ending L-----------------
	     else
mailx -s "$MAIL_LOG_SUB4" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE3 file not found while checking listener log status.
EOF
		 exit 1
             fi
             echo *--------------Ending E-----------------
          else
mailx -s "$MAIL_LOG_SUB7" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE2 file with zero bytes while checking listener status.
EOF
	      exit 1
          fi
          echo *--------------Ending D-----------------
      else
mailx -s "$MAIL_LOG_SUB2" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE2 file not found while checking listener status.
EOF
	  exit 1
      fi
      echo *--------------Ending C-----------------
   fi
   echo *--------------Ending B-----------------
else
mailx -s "$MAIL_LOG_SUB2" "$MAIL_LOG_TO_DBA" <<EOF
E R R O R: $FILE1 file not found while checking listener status.
EOF
    exit 1
fi
echo *-----------Ending A------------------

