# turboracle

Fully automated script to install **Oracle Database 12.1.0.2.0 Enterprise** on **Oracle Linux 7.2** with zero effort. Other releases are not supported. 

## Prerequisites

### Utilities

- [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads) ( [Microsoft Hyper-V](https://msdn.microsoft.com/en-us/virtualization/hyperv_on_windows/quick_start/walkthrough_install) / [VMware Workstation Player](https://www.vmware.com/go/downloadplayer) )
- [Oracle SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/downloads/index.html)
- [FileZilla](https://filezilla-project.org/download.php?type=client)
- [PuTTY](https://blog.splunk.net/64bit-putty/)

### Files

- [Oracle Linux 7.2 Boot ISO](https://edelivery.oracle.com/linux)
- [Oracle Database 12c](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)

## Oracle Linux

- Set up FQDN properly
- Set up install repo: `public-yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64`
- Use `Minimal` install
- Upload the two Oracle Database installer ZIPs to `/root` with FileZilla.

## Installation

~~~
sudo -i
yum -y install git
git clone https://github.com/bviktor/turboracle.git
/root/turboracle/install.sh
~~~

## Usage

EM Database Express (the web interface) is available at:

~~~
https://oracle.foobar.lan:5500/em/
~~~

For SQL Developer access:

- Username: `sys`
- Password: the one you enter during Oracle Database install
- Connection type: `Basic`
- Role: `SYSDBA`
- Hostname: the FQDN of the host
- Port: `1521`
- SID: `orcl`

To control the service, add the user to the `dba` group, then:

~~~
sudo /bin/systemctl status oracle12.service
sudo /bin/systemctl start oracle12.service
sudo /bin/systemctl stop oracle12.service
sudo /bin/systemctl restart oracle12.service
~~~

Service logs are available at `/var/log/oracle12`.
