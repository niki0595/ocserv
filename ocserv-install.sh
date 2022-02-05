#!/usr/bin/env bash

certificates() {

hostname=$(hostname -I|cut -f1 -d ' ')
echo
read -p "Enter IP address [$hostname]: " ip
ip=${ip:-$hostname}

mkdir -p certificates
cd certificates

cat << EOF > ca.tmpl
cn = "VPN CA"
organization = "Big Corp"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
EOF

certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem

cat << EOF > server.tmpl
#yourIP
cn=$ip
organization = "my company"
expiration_days = 3650
signing_key
encryption_key
tls_www_server
EOF

certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

cp ~/certificates/server-key.pem /etc/ocserv/
cp ~/certificates/server-cert.pem /etc/ocserv/
}

install() {

echo -e "\e[32mInstalling gnutls-bin\e[39m"
apt install -y gnutls-bin

echo -e "\e[32mInstalling ocserv\e[39m"
apt install -y ocserv

cp -f "$0" /etc/ocserv/

sed -i -e 's@auth = "@#auth = "@g' /etc/ocserv/ocserv.conf
sed -i -e 's@auth = "pam@auth = "#auth = "pam"@g' /etc/ocserv/ocserv.conf
sed -i -e 's@udp-port =@#udp-port =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@max-same-clients = 2@max-same-clients = 1@g' /etc/ocserv/ocserv.conf
sed -i -e 's@try-mtu-discovery = @try-mtu-discovery = true@g' /etc/ocserv/ocserv.conf
sed -i -e 's@dns = @#dns = @g' /etc/ocserv/ocserv.conf
sed -i -e 's@# multiple servers.@dns = 8.8.8.8@g' /etc/ocserv/ocserv.conf
sed -i -e 's@route =@#route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@no-route =@#no-route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@cisco-client-compat@cisco-client-compat = true@g' /etc/ocserv/ocserv.conf
sed -i -e 's@##auth = "#auth = "pam""@auth = "plain[passwd=/etc/ocserv/ocpasswd]"@g' /etc/ocserv/ocserv.conf

sed -i -e 's@server-cert = /etc/ssl/certs/ssl-cert-snakeoil.pem@server-cert = /etc/ocserv/server-cert.pem@g' /etc/ocserv/ocserv.conf
sed -i -e 's@server-key = /etc/ssl/private/ssl-cert-snakeoil.key@server-key = /etc/ocserv/server-key.pem@g' /etc/ocserv/ocserv.conf

certificates

echo
read -p "Enter a username: " username
ocpasswd -c /etc/ocserv/ocpasswd $username

sed -i -e 's@#net.ipv4.ip_forward=@net.ipv4.ip_forward=1@g' /etc/sysctl.conf

iptables -t nat -A POSTROUTING -j MASQUERADE
iptables-save > /etc/iptables.rules

cat << EOF > /etc/network/if-pre-up.d/iptables
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOF

chmod +x /etc/network/if-pre-up.d/iptables

sysctl -p /etc/sysctl.conf
echo -e "\e[32mStopping ocserv service\e[39m"
service ocserv stop
echo -e "\e[32mStarting ocserv service\e[39m"
service ocserv start

echo "OpenConnect Server Configured Succesfully"

}

uninstall() {
apt-get purge -y ocserv
}

addUser() {

echo
read -p "Enter a username: " username
ocpasswd -c /etc/ocserv/ocpasswd $username

}

showUsers() {
cat /etc/ocserv/ocpasswd
}

deleteUser() {
echo
read -p "Enter a username: " username
ocpasswd -c /etc/ocserv/ocpasswd -d $username
}

lockUser() {
echo
read -p "Enter a username: " username
ocpasswd -c /etc/ocserv/ocpasswd -l $username
}

unlockUser() {
echo
read -p "Enter a username: " username
ocpasswd -c /etc/ocserv/ocpasswd -u $username
}

if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

cd ~

if [ "$1" == "cert" ]; then
	certificates
	exit
fi

PS3='Please enter your choice: '
options=("Install" "Uninstall" "Add User" "Change Password" "Show Users" "Delete User" "Lock User" "Unlock User" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            install
			break
            ;;
        "Uninstall")
            uninstall
			break
            ;;
        "Add User")
            addUser
			break
            ;;
        "Change Password")
            addUser
			break
            ;;
        "Show Users")
	    showUsers
			break
	    ;;
        "Delete User")
	    deleteUser
			break
	    ;;
        "Lock User")
	    lockUser
			break
	    ;;
        "Unlock User")
	    unlockUser
			break
	    ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

