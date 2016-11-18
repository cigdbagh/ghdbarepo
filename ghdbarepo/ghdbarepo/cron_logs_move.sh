#!/bin/sh
# Name     :  cron_logs_move.sh
# Author   :  Ramesh Kalyandrug
# created  :  11/07/16

CURR_DATE=`date +%b%Y%d`
echo $CURR_DATE
mkdir -p /tmp/logs/old/${CURR_DATE}
mv /tmp/logs/*.log /tmp/logs/old/${CURR_DATE}/
