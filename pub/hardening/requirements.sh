#######################################################################################
# Install project Requirements
#######################################################################################
#!/bin/bash
#yum localinstall -y wget 
wget ftp://192.168.35.20/pub/hardening/protobuf-2.5.0-8.el7.x86_64.rpm
wget ftp://192.168.35.20/pub/hardening/scap-security-guide-0.1.36-10.el7.centos.noarch.rpm
wget ftp://192.168.35.20/pub/hardening/usbguard-0.7.0-3.el7.x86_64.rpm
wget ftp://192.168.35.20/pub/hardening/usbguard-tools-0.7.0-3.el7.x86_64.rpm
yum localinstall -y protobuf
yum localinstall -y scap-security-guide
yum localinstall -y usbguard
yum localinstall -y usbguard-tools
# Enable USB Guard
usbguard generate-policy > /etc/usbguard/rules.conf
systemctl disable usbguard.service
systemctl stop usbguard.service

# Disable Bluetooth Service
systemctl mask bluetooth.service

# Create ssh-admin user
useradd -m -c "System Administrator" -G sshusers ssh-admin
echo !QAZ2wsx3edc1234 | passwd ssh-admin --stdin

# Join admin user to sshusers,wheel group's
usermod -a -G sshusers,wheel admin
usermod -a -G wheel zabbix

# Change ssh port and banner
sed -i 's/#Port 22/Port 34297/' /etc/ssh/sshd_config
sed -i 's/ClientAliveInterval*/ClientAliveInterval 3600/' /etc/ssh/sshd_config
sed -i 's/ClientAliveCountMax*/ClientAliveCountMax 5/' /etc/ssh/sshd_config

figlet DNS PROJECT > /etc/issue.net
echo "##############################################################################################################################
#                                                      Welcome to Test Project                                                      
#                                   All connections are monitored and recorded                                         
#                          Disconnect IMMEDIATELY if you are not an authorized user!                    
##############################################################################################################################
" >> /etc/issue.net
systemctl enable sshd.service
systemctl restart sshd.service

# Add ssh port to iptable
#touch /etc/sysconfig/iptables
#touch /etc/sysconfig/ip6tables
systemctl start iptables.service
systemctl start ip6tables.service
systemctl enable iptables.service
systemctl enable ip6tables.service
iptables -I INPUT -p tcp --dport 34297 -j ACCEPT
iptables -I INPUT -p tcp --dport 10050 -j ACCEPT
iptables-save >> /etc/sysconfig/iptables
ip6tables-save >> /etc/sysconfig/ip6tables

# NOPASSWD for ssh-admin(Ansible)
# Zabbix configuration
echo "#PDNS
# Zabbix Agent PDNS
Defaults:zabbix !requiretty
zabbix ALL=NOPASSWD: /usr/bin/pdns_control

#PDNS Recursor
# Zabbix Agent PDNS Recursor
Defaults:zabbix !requiretty
zabbix ALL=NOPASSWD: /usr/bin/rec_control
" >> /etc/sudoers
sed -i  '/^root/a ssh-admin  ALL=(ALL:ALL)   NOPASSWD:ALL' /etc/sudoers

# PDNS EDITOR config
echo "export EDITOR=vim
" >> /home/ssh-admin/.bashrc
systemctl stop firewalld.service
systemctl disable firewalld.service

# Install OMS Agent and its dependencies
echo "export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_INDEX=true
export PIP_FIND_LINKS=http://192.168.35.20/Repo/pip-packages/
export PIP_TRUSTED_HOST=192.168.35.20
" >> /etc/bashrc
source /etc/bashrc
#wget http://192.168.35.20/Repo/all-agent-repo/oms-agent-1.0-1.el7.noarch.rpm
#yum localinstall -y oms-agent-1.0-1.el7.noarch.rpm
