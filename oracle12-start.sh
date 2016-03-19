#!/bin/sh

# Start Database
sqlplus / as sysdba << EOF >> /var/log/oracle12 2>&1
STARTUP;
EXIT;
EOF

# Start Listener
lsnrctl start >> /var/log/oracle12 2>&1
