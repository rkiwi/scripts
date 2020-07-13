#!/bin/bash

#
## rkiwi
#

# run script with arguments:
# -reset | change name of user to ADMIN and reset password 
# --hardreset | change name, reset password and give privelege
# if you don't want to reset password - write IP-address in first argument
# if you have diffrent mnetmask - write it on second argument (you can write default netmask)
# if you have diffrent default gateway IP - write it on third argument

regex="([0-9]{1,3}[\.]){3}[0-9]{1,3}"
flag=0
name=******** # change "********" with your default username
pass=******** # change "********" with your password

function checkStatus {
	if (( $? != 0 )); then
		flag=1
		break
	fi
}

if [[ "$1" == "--reset" || "$1" == "--hardreset" ]]; then
	while (( flag == 0 )); do
		if [[ "$1" == "--reset" ]]; then
			ipmitool user set name 2 $name > /dev/null 2>&1
			checkStatus
			ipmitool user set password 2 $pass > /dev/null 2>&1
			checkStatus
			flag=2
		else
			ipmitool user enable 2 > /dev/null 2>&1
			checkStatus
			ipmitool user set name 2 $name > /dev/null 2>&1
			checkStatus
			ipmitool user priv 2 4 1 > /dev/null 2>&1
			checkStatus
			ipmitool channel setaccess 1 2 link=on ipmi=on callin=on privilege=4 > /dev/null 2>&1
			checkStatus
			ipmitool user set password 2 $pass > /dev/null 2>&1
			checkStatus
			flag=2
		fi
	done
	if (( $flag != 2 )); then
		printf "\e[31mSomething wrong! Change password in manual mode\e[0m\n"; shift; sleep 5
	else
		printf "\n\e[31m=======================================\e[0m\n"
		printf " NEW Login:Password — \e[96m$name:$pass\n"
		printf "\e[31m=======================================\e[0m\n\n"
		sleep 5
		shift
	fi
fi

if [ -z "$1" ]
then
	printf "\e[31mError! Run script with IP or Hostname\e[0m\n"; exit 1
else
		input=$1
fi
ip=$input
if [[ "$input" =~ $regex ]]
then
	IFS='.'; read -r i1 i2 i3 i4 <<< $input; IFS=' '
else
    # here script will try to find IP-address by your DNS, if you have more than 2 domains - need to change logic
    # if you have 1 domain - chacnge "domain_0"
    # if you doesn't have domains - remove "domain_0" or use IP ¯\_(ツ)_/¯ 
	hostname=$input
	host $hostname".domain_0" > /dev/null 2>&1
	result1=$?
	host $hostname".domain_1" > /dev/null 2>&1
	result2=$?
	let "result = result1 - result2"
	case "$result" in
		-1)	ip=$(host $hostname".domain_0" 2>&1 | head -n 1 | awk '{print $NF}');printf "\nAddress of $hostname".domain_0" found!\n\n";;
		0)	printf "\e[31mError! Run script with IP\e[0m\n";exit 1;;
		1)	ip=$(host $hostname".domain_1" 2>&1 | head -n 1 | awk '{print $NF}');printf "\nAddress of $hostname".domain_1" found!\n\n";;
	esac
	IFS='.'; read -ra i1 i2 i3 i4 <<< $ip; IFS=' ' # on MACos this doesn't work correctly, if you want to check - use CentOS or Ubuntu
fi

if [ -z "$2" ]
then
	netm="********" # change "********" with your default netmask
else 
	netm=$2
fi

if [ -z "$3" ]
then
	defg="${i1}.${i2}.${i3}.1"
else 
	defg=$3
fi
echo "IPMI IP:		"$ip
echo "NETMASK:		"$netm
echo "DEFAULT GATEWAY:	"$defg
echo -ne '                          (20%)\r'
printf "\e[96mSet static address\e[0m\n"
ipmitool lan set 1 ipsrc static > /dev/null 2>&1
echo -ne '                          (40%)\r'
printf "\e[96mSet IPMI IP\e[0m\n"
ipmitool lan set 1 ipaddr $ip > /dev/null 2>&1
echo -ne '                          (60%)\r'
printf "\e[96mSet NETMASK\e[0m\n"
ipmitool lan set 1 netmask $netm > /dev/null 2>&1
echo -ne '                          (80%)\r'
printf "\e[96mSet DEFAULT GATEWAY\e[0m\n"
ipmitool lan set 1 defgw ipaddr $defg > /dev/null 2>&1
echo -ne '                          (100%)\r'
printf "\e[96mKill discover process\e[0m\n"
echo -ne '\n'
printf "\e[96m=====================================\e[0m\n"
printf "\e[96mDone!\e[0m\n"
printf "\e[96m=====================================\e[0m\n\n"