#!/bin/sh

# Stop Listener
lsnrctl stop >> /var/log/oracle12 2>&1

# Stop Database
sqlplus / as sysdba << EOF >> /var/log/oracle12 2>&1
SHUTDOWN IMMEDIATE;
EXIT;
EOF
