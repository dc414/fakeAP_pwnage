fakeAP_pwnage
=============

A fakeAP to sniff traffic or get CC numbers. This only works with Backtrack 5 on a 64bit system.

Setup
=====
Because sslstrip needs write access to the current working dir move fakeAP.sh to ~/ and thats it! Then just run that shit!

Usage
=====
Usage: user@user:~# sh fakeAP.sh <SSID> <type>
Types: sniff / CC
sniff - runs sslstrip and just allows you to sniffer traffic
CC - attempts to get victims CC info
