#!/bin/sh

# check root
if [ $(whoami) != 'root' ]
then
	echo "TURBORACLE: Error: make sure to run this script as root!"
	exit 1
fi

# gotta go home...
ROOT_DIR=$(cd $(dirname $0) && pwd)
if [ ${ROOT_DIR} != '/root/turboracle' ]
then
	echo "TURBORACLE: Error: this script should be located at /root/turboracle!"
	exit 2
fi

# check installer files
if	[ ! -f "/root/linuxamd64_12102_database_1of2.zip" ] || [ ! -f "/root/linuxamd64_12102_database_2of2.zip" ]
then
	echo "TURBORACLE: Error: Oracle installer files are missing!"
	exit 3
fi

echo "TURBORACLE: Making sure you're up-to-date..."
yum -y update

echo "TURBORACLE: Installing some basic system tools..."
yum -y install mc git bind-utils psmisc bash-completion ntp wget policycoreutils-python setools-console unzip

echo "TURBORACLE: Enabling NTP..."
systemctl enable ntpd.service
systemctl restart ntpd.service

update_profile ()
{
	if [ ! -f "$1.orig" ]
	then
		cp "$1" "$1.orig"
	fi

	cat << EOF >> "$1"
export ORACLE_HOME=/home/oracle/app/oracle/product/12.1.0/dbhome_1
export ORACLE_BASE=/home/oracle/app/oracle
export ORACLE_SID=orcl
export PATH=$PATH:/home/oracle/app/oracle/product/12.1.0/dbhome_1/bin
EOF
}

echo "TURBORACLE: Modifying global Bash profile for Oracle usage..."
update_profile "/etc/skel/.bash_profile"

echo "TURBORACLE: Please enter non-root username to be used for DB management..."
read -p 'Regular User: ' UNAME
while [ ! -d "/home/${UNAME}" ]
do
	echo "TURBORACLE: Error: /home/${UNAME} doesn't exist, please try again."
	read -p 'Regular User: ' UNAME
done
update_profile "/home/${UNAME}/.bash_profile"
usermod -a -G dba ${UNAME}

echo "TURBORACLE: Installing Oracle 12 preinstall RPM..."
yum -y install oracle-rdbms-server-12cR1-preinstall

echo "TURBORACLE: Generating response file based on hostname..."
HNAME_LONG=$(hostname)
HNAME_SHORT=$(hostname -s)
sed "s/fixme.hostname/${HNAME_LONG}/" "${ROOT_DIR}/db.rsp.tmpl" > "${ROOT_DIR}/db.rsp"
sed -i "s/fixme.dbname/orcl.${HNAME_LONG}/" "${ROOT_DIR}/db.rsp"

echo "TURBORACLE: Setting up password for SYS, SYSTEM and DBSNMP..."
read -s -p 'Oracle Password: ' ORACLEPASS
sed -i "s/fixme.password/$ORACLEPASS/" "${ROOT_DIR}/db.rsp"
sed "s/fixme.password/$ORACLEPASS/" "${ROOT_DIR}/cfgrsp.properties.tmpl" > "${ROOT_DIR}/cfgrsp.properties"

echo "TURBORACLE: Fixing hostname resolution..."
sed -i.orig "s/127.0.0.1.*/127.0.0.1 ${HNAME_LONG} ${HNAME_SHORT} localhost/" /etc/hosts

home_copy ()
{
	cp -f "${ROOT_DIR}/$1" "/home/oracle/"
	restorecon -v "/home/oracle/$1"
	chown oracle.oinstall "/home/oracle/$1"
	chmod 754 "/home/oracle/$1"
}

echo "TURBORACLE: Installing systemd service unit..."
cp "${ROOT_DIR}/oracle12.service" "/etc/systemd/system/"
mkdir -p "/etc/systemd/system/oracle12.service.d"
cp "${ROOT_DIR}/env.conf" "/etc/systemd/system/oracle12.service.d/"
restorecon -rv "/etc/systemd/system"
systemctl daemon-reload
systemctl enable oracle12
home_copy "oracle12-start.sh"
home_copy "oracle12-stop.sh"
touch "/var/log/oracle12"
restorecon -v "/var/log/oracle12"
chown oracle.dba "/var/log/oracle12"
chmod 0640 "/var/log/oracle12"

echo "TURBORACLE: Addig sudo rules..."
cp "oracle12-sudo" "/etc/sudoers.d/"
restorecon -v "/etc/sudoers.d/oracle12-sudo"
chmod 0440 "/etc/sudoers.d/oracle12-sudo"

allow_service ()
{
	firewall-cmd --new-service="$1" --permanent
	sed -i "s@</service>@<port protocol=\"tcp\" port=\""$2"\"/></service>@" "/etc/firewalld/services/$1.xml"
	firewall-cmd --add-service="$1" --permanent
}

echo "TURBORACLE: Opening ports for Enterprise Manager and SQL Developer..."
allow_service "oracle-em" "5500"
allow_service "oracle-sql" "1521"
firewall-cmd --reload

echo "TURBORACLE: Granting access to Oracle binaries..."
chmod 755 /home/oracle

echo "TURBORACLE: Unzipping Oracle installer files..."
unzip -q /root/linuxamd64_12102_database_1of2.zip -d /home/oracle
unzip -q /root/linuxamd64_12102_database_2of2.zip -d /home/oracle
restorecon -rv /home/oracle/database
chown -R oracle.oinstall /home/oracle/database

echo "TURBORACLE: Installing Oracle Database..."
home_copy "db.rsp"
home_copy "cfgrsp.properties"
sudo -u oracle /home/oracle/database/runInstaller -responseFile /home/oracle/db.rsp -showProgress -silent -waitforcompletion
/home/oracle/app/oraInventory/orainstRoot.sh
/home/oracle/app/oracle/product/12.1.0/dbhome_1/root.sh
sudo -u oracle /home/oracle/app/oracle/product/12.1.0/dbhome_1/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/home/oracle/cfgrsp.properties
rm -f "/home/oracle/db.rsp"
rm -f "/home/oracle/cfgrsp.properties"

echo "TURBORACLE: Starting Oracle 12..."
systemctl start oracle12.service
