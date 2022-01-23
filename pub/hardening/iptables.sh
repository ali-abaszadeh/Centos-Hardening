#!/bin/sh

function usage() {
cat << EOF
usage: $0 [options]

  -h,--help	Show this message

  --http	Allows HTTP (80/tcp)
  --https	Allows HTTPS (443/tcp)
  --dns		Allows DNS (53/tcp/udp)
  --ntp		Allows NTP (123/tcp/udp)
  --rsyslog	Allows RSYSLOG (514/tcp/udp)
  --kerberos	Allows Kerberos (88,464/tcp/udp)
  --ldap	Allows LDAP (389/tcp/udp)
  --ldaps	Allows LDAPS (636/tcp/udp)
  --iscsi	Allows iSCSI (3260/tcp)
  --mysql	Allows MySQL (3306/tcp)

Configures iptables firewall rules for CentOS.
 
EOF
}

# Get options
OPTS=`getopt -o h --long http,https,dns,ldap,ldaps,iscsi,idm,krb5,kerberos,rsyslog,bootp,ntp,mysql,mariadb,help -- "$@"`
if [ $? != 0 ]; then
	exit 1
fi
eval set -- "$OPTS"

while true ; do
    case "$1" in
	--http) HTTP=1 ; shift ;;
	--https) HTTPS=1 ; shift ;;
	--dns) DNS=1 ; shift ;;
	--ldap) LDAP=1 ; shift ;;
	--ldaps) LDAPS=1 ; shift ;;
	--kerberos) KERBEROS=1 ; shift ;;
	--idm) KERBEROS=1 ; LDAP=1; LDAPS=1; DNS=1; NTP=1; HTTPS=1; shift ;;
	--krb5) KERBEROS=1 ; shift;;
	--iscsi) ISCSI=1 ; shift ;;
	--ntp) NTP=1 ; shift ;;
	--mariadb) MARIADB=1 ; shift ;;
	--rsyslog) RSYSLOG=1 ; shift ;;
        --) shift ; break ;;
        *) usage ; exit 0 ;;
    esac
done


# Check for root user
if [[ $EUID -ne 0 ]]; then
	tput setaf 1;echo -e "\033[1mPlease re-run this script as root!\033[0m";tput sgr0
	exit 1
fi

# Check if iptables package is installed
if [ ! -e $(which iptables) ]; then
	echo "ERROR: The iptables package is not installed."
	exit 1
fi

# Backup originial configuration
if [ ! -e /etc/sysconfig/iptables.orig ]; then
	cp /etc/sysconfig/iptables /etc/sysconfig/iptables.orig
fi
if [ ! -e /etc/sysconfig/ip6tables.orig ]; then
	cp /etc/sysconfig/ip6tables /etc/sysconfig/ip6tables.orig
fi


# Basic rule set - allows established/related pakets and SSH through firewall
cat <<EOF > /etc/sysconfig/iptables
#################################################################################################################
# HARDENING SCRIPT IPTABLES Configuration
#################################################################################################################
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow Traffic that is established or related
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow ICMP (Ping)
-A INPUT -p icmp -j ACCEPT
# Allow Traffic on LOCALHOST/127.0.0.1
-A INPUT -i lo -j ACCEPT
#### SSH/SCP/SFTP
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
EOF

if [ ! -z $DNS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### DNS Services (ISC BIND/IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
EOF
fi

if [ ! -z $HTTP ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### HTTPD - Recommend forwarding traffic to HTTPS 443
####   Recommended Article: http://www.cyberciti.biz/tips/howto-apache-force-https-secure-connections.html
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
EOF
fi


if [ ! -z $HTTPS ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### HTTPS
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
EOF
fi

if [ ! -z $RSYSLOG ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### RSYSLOG Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 514 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 514 -j ACCEPT
EOF
fi


if [ ! -z $ISCSI ]; then
cat <<EOF >> /etc/sysconfig/iptables
#### iSCSI Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3260 -j ACCEPT
EOF
fi

#if [ ! -z $MARIADB ]; then
#cat <<EOF >> /etc/sysconfig/iptables
#### MariaDB/MySQL Server
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
#EOF
#fi

cat <<EOF >> /etc/sysconfig/iptables
#################################################################################################################
# Block timestamp-request and timestamp-reply

-A INPUT -p ICMP --icmp-type timestamp-request -j DROP
-A INPUT -p ICMP --icmp-type timestamp-reply -j DROP
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF

# IPv6 Basic rule set - allows established/related pakets and SSH through firewall
cat <<EOF > /etc/sysconfig/ip6tables
#################################################################################################################
# HARDENING SCRIPT IPTABLES Configuration
#################################################################################################################
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow Traffic that is established or related
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Allow ICMP (Ping)
-A INPUT -p ipv6-icmp -j ACCEPT
# Allow Traffic on LOCALHOST/127.0.0.1
-A INPUT -i lo -j ACCEPT
#### SSH/SCP/SFTP
-A INPUT -m state --state NEW -m tcp -p tcp --dport 34297 -j ACCEPT
EOF

if [ ! -z $DNS ]; then
cat <<EOF >> /etc/sysconfig/ip6tables
#### DNS Services (ISC BIND/IdM/IPA)
-A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
EOF
fi

if [ ! -z $HTTP ]; then
cat <<EOF >> /etc/sysconfig/ip6tables
#### HTTPD - Recommend forwarding traffic to HTTPS 443
####   Recommended Article: http://www.cyberciti.biz/tips/howto-apache-force-https-secure-connections.html
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
EOF
fi

#if [ ! -z $NTP ]; then
#cat <<EOF >> /etc/sysconfig/ip6tables
#### NTP Server
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 123 -j ACCEPT
#-A INPUT -m state --state NEW -m udp -p udp --dport 123 -j ACCEPT
#EOF
#fi

#if [ ! -z $LDAP ]; then
#cat <<EOF >> /etc/sysconfig/ip6tables
#### LDAP (IdM/IPA)
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 389 -j ACCEPT
#-A INPUT -m state --state NEW -m udp -p udp --dport 389 -j ACCEPT
#EOF
#fi

if [ ! -z $HTTPS ]; then
cat <<EOF >> /etc/sysconfig/ip6tables
#### HTTPS
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
EOF
fi

if [ ! -z $RSYSLOG ]; then
cat <<EOF >> /etc/sysconfig/ip6tables
#### RSYSLOG Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 514 -j ACCEPT
-A INPUT -m state --state NEW -m udp -p udp --dport 514 -j ACCEPT
EOF
fi

#if [ ! -z $LDAPS ]; then
#cat <<EOF >> /etc/sysconfig/ip6tables
#### LDAPS - LDAP via SSL (IdM/IPA)
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 636 -j ACCEPT
#-A INPUT -m state --state NEW -m udp -p udp --dport 636 -j ACCEPT
#EOF
#fi

if [ ! -z $ISCSI ]; then
cat <<EOF >> /etc/sysconfig/ip6tables
#### iSCSI Server
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3260 -j ACCEPT
EOF
fi

#if [ ! -z $MARIADB ]; then
#cat <<EOF >> /etc/sysconfig/ip6tables
#### MariaDB/MySQL Server
#-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT
#EOF
#fi

cat <<EOF >> /etc/sysconfig/ip6tables
#################################################################################################################
# Limit Echo Requests - Prevents DoS attacks
-A INPUT -p icmpv6 --icmpv6-type 128 -m limit --limit 900/min -m hl --hl-eq 255 -j ACCEPT
-A OUTPUT -p icmpv6 --icmpv6-type 129 -m limit --limit 900/min -m hl --hl-eq 255 -j ACCEPT
-A INPUT -p icmpv6 --icmpv6-type 128 -m limit --limit 900/min -m hl --hl-lt 255 -j DROP
-A OUTPUT -p icmpv6 --icmpv6-type 129 -m limit --limit 900/min -m hl --hl-let 255 -j DROP
-A INPUT -j REJECT --reject-with icmp6-adm-prohibited
-A FORWARD -j REJECT --reject-with icmp6-adm-prohibited
COMMIT
EOF

exit 0
