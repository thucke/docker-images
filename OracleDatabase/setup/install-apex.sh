#!/bin/bash
##########################################################
# Set the name of the downloaded APEX installation archive
##########################################################
APEX_FILE=apex_5.1.3.zip
###############################

unzip $ORACLE_BASE/scripts/setup/$APEX_FILE -d $ORACLE_BASE/scripts/setup

cd $ORACLE_BASE/scripts/setup/apex
su -p oracle -c "sqlplus / as sysdba <<EOF
spool $ORACLE_BASE/scripts/setup/installApex.log
@apexins.sql SYSAUX SYSAUX TEMP /i/
@apex_epg_config.sql $ORACLE_BASE/scripts/setup
@apxchpwd.sql
EOF"

rm -rf $ORACLE_BASE/scripts/setup/apex