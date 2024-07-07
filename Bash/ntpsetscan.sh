#!/bin/bash

function valid_ip() {
	local ip=$1
	local stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=("$ip")
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 &&
			${ip[2]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

function myusage() {
	echo "Usage: $(basename "$0" .sh) <IP missing last octet> "
	echo "Example: $(basename "$0" .sh) 192.168.0"
}

if [[ $# -eq 1 ]]; then
	if [[ $1 == 'valid_ip' ]]; then
		for i in {1..254}; do
			ntpdate -q "$1.$i"
		done
	else
		echo "ERROR: Missing flag or too many arguments"
		myusage
	fi
else
	echo "ERROR: Missing flag or too many arguments"
	myusage
fi
