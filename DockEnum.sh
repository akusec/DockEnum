#/bin/bash

echo ""
echo "####################################################################"
echo "## DockEnum : Tool to enumerate ways to escape on container"
echo "## Made by Akusec Team"
echo "####################################################################"
echo ""

if [[ $(whoami) != "root" ]]; then
	echo "[-] It seems you are not root : you may have some troubles with this script"
fi

### Check if you are in a container
echo "---------------------------------"
echo "## Checking environment..."
if cat /proc/1/cgroup | grep -q "docker"; then
	echo "[+] You're in Docker Container";
else 
	echo "[-] You are not in a Docker container..."; 
	echo "[-] This tool is used to escape from a Docker container"
	echo "[-] Exiting..."
	exit 1
fi


### Get Sys infos
distrib=$(grep -w NAME /etc/*-release | sed -e 's/.*"\(.*\)".*/\1/')
kernel=$(uname -a)
arch=$(uname -m)

echo "[*] Distribution : $distrib"
echo "[*] Kernel : $kernel"
echo "[*] Arch : $arch"
echo "---------------------------------"

### Check if privileged mode is enabled
echo "## Checking privileged mode on container..."
ip link add dummy0 type dummy 2> /dev/null
if [[ $? -eq 0 ]]; then
	echo "[+] The container is running as privileged mode !"
	# clean the dummy0 link
	ip link delete dummy0 2> /dev/null
fi

echo "---------------------------------"

## Check if privileged mode is enabled
echo "## Checking Docker Socket..."
dock_sock=$(find / -name docker.sock 2>/dev/null)
if [ -n "$dock_sock" ]; then
	echo "[+] Found a mounted docker socket here : $dock_sock"
fi

echo "---------------------------------"

echo "## Checking capabilites on the container..."
### Check Capsh availability
if type capsh >/dev/null 2>&1 ; then
	echo "[+] Capsh command is available"
else
	echo "[-] No capsh available... Verify if capsh bin exists on the system"
	capsh=$(find / -name capsh)
	if [[ -n "$capsh" ]]; then
		echo "[+] Found a capsh binary at path $capsh"
	else
		echo "[-] Capsh not found... Installing it..."
		case $distrib in
			*"Alpine"* ) 
				apk -qq update > /dev/null 2>&1
				apk -qq add libcap > /dev/null 2>&1
				installed=1
				;;
			*"Debian"* ) 
				apt-get -qq update > /dev/null 2>&1
				apt-get -qq install libcap2-bin > /dev/null 2>&1
				installed=1
				;;
		esac
	fi
fi

### Verify capabilities
if [ -n "$capsh" ]; then
	capabilities=$($capsh --print)
else
	capabilities=$(capsh --print)
fi

found_cap=0
if [[ $(echo $capabilities | grep "sys_admin") ]]; then
	echo "[+] SYS_ADMIN capability is enabled"
	found_cap=1
fi

if [[ $(echo $capabilities | grep "sys_ptrace") ]]; then
	echo "[+] SYS_PTRACE capability is enabled"
	found_cap=1
fi

if [[ $(echo $capabilities | grep "sys_module") ]]; then
	echo "[+] SYS_MODULE capability is enabled"
	found_cap=1
fi

if [[ $(echo $capabilities | grep "dac_read_search") ]]; then
	echo "[+] DAC_READ_SEARCH capability is enabled"
	found_cap=1
fi

if [[ $(echo $capabilities | grep "dac_override") ]]; then
	echo "[+] DAC_OVERRIDE capability is enabled"
	found_cap=1
fi

if [ "$found_cap" -eq "0" ]; then
	echo "[-] No capabilities found..."
fi


if [ "$installed" -eq 1 ]; then
	case $distrib in
		*"Alpine"* ) 
			apk -qq del libcap > /dev/null 2>&1
			;;
		*"Debian"* ) 
			apt-get -qq remove --purge libcap2-bin > /dev/null 2>&1
			;;
	esac
fi
echo "---------------------------------"
exit 0