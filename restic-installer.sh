#!/bin/bash
#
# restic install script
#
# @version  0.1.0
# @date	2014-07-30
# @license  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# set -x
# Set environment
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# epic logo incoming
echo -e "\033[91m    ___  _______________________ \033[0m"
echo -e "\033[91m   / _ \/ __/ __/_  __/  _/ ___/ \033[0m"
echo -e "\033[91m  / , _/ _/_\ \  / / _/ // /__   \033[0m"
echo -e "\033[91m /_/|_/___/___/ /_/ /___/\___/   \033[0m \033[32mInstaller \033[0m"
echo -e "==========================================="
echo -e "\nFast, secure, efficient backup program \n\nWeb: https://restic.net/\nGithub: https://github.com/restic/restic\nRTFM: https://restic.readthedocs.io/en/stable/"
echo -e "===========================================\n"

if [ "$UID" != "0" ]; then
	sudoPath=$(which sudo)
	if [ ! -w "${sudoPath}" ]; then
		echo -e "\033[91mThis installer requires root privileges!\033[0m"
		if [ ! -w "restic-installer.sh" ]; then
			wget --quiet https://github.com/necenzurat/restic-installer/raw/master/restic-installer.sh 
		fi
		echo -e "You can try to run it again like this:"
		echo -e "$ sudo bash restic-installer.sh\n"
		exit 1
	else
		echo -e "\033[91msudo was not found, please run this installer as root!\033[0m"
		exit 1
	fi 
fi

function update (){
	echo -e "\033[32mHint: restic can self update, you just need to execute this command: \033[0m\n"
	echo -e "$ ${installedPath} self-update\n"
	echo -e "===========================================\n"
	installedPath=$(which restic)
	${installedPath} self-update
}

function osFlavour () {
	echo $(uname | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/")
}

function osType () {
	osType=$(uname -m)
	case $osType in
		x86_64|amd64)
		osType='amd64'
		;;
		i?86|x86)
		osType='386'
		;;
		arm*)
		osType='arm'
		;;
		aarch64)
		osType='arm64'
		;;
		*)
		osType="unsupported"
		exit 1;
		;;
	esac
	echo $osType;
}

if [[ $(osType) == "unsupported" ]]; then
	echo -e "\033[91m"$(uname -m)" is unsupported by this installer, try installing it from source. \033[0m"
	echo -e "\033[91mPlease try downloading and installing it manually or compile it by source: \033[0m"
	echo -e "https://github.com/restic/restic/releases\n\n"
	exit 1;
fi

function installCrontab () {	
	if [ ! -e /etc/crontab ] || [ ! -w /etc/crontab ]; 
	then 
		(crontab  -l | grep -v "restic self-update") | crontab -u $USER -
		crontab -u $USER -l 2> /dev/null | { cat; echo "0 0 * * * ${installPath}/restic self-update > /var/log/restic-update.log 2>&1"; } | crontab -u $USER -
		echo -e "A cron job has been set in crontab, check it running crontab -l, and the output will be sent to /var/log/restic-update.log"
	else 
		(cat /etc/crontab | grep -v "restic self-update")  > /etc/crontab.tmp && mv /etc/crontab.tmp /etc/crontab
		echo -e "\n# Restic Auto Update, you can remove this if you don't like updates\n0 0 * * *  root  ${installPath}/restic self-update > /var/log/restic-update.log 2>&1" >> /etc/crontab;
		echo -e "A cron job has been set in /etc/crontab, and the output will be sent to /var/log/restic-update.log"
	fi
}

function install() {
	# fix for low privilege... plebs
	installPath="/usr/bin";
	if [ ! -w "${installPath}" ]; 
	then 
		installPath="/usr/local/bin";   
	fi

	resticGithub=$(wget --server-response -O- "https://api.github.com/repos/restic/restic/releases/latest" --show-progress 2>&1)
	if [[ $? -ne 0 ]]; then
		echo -e "\033[91mThere was a problem connecting to https://api.github.com/repos/restic/restic/releases/latest for the latest version from Github!\033[0m"
		echo -e "Please check your internetz and try again later!";
		exit 1; 
	fi

	# this, right here is awesome and took a shitty long time to write
	# fucking bash
	# please refactor this if you know bash
	resticVersion=$(echo "$resticGithub" | grep "tag_name" | cut -d '"' -f 4  | cut -d 'v' -f 2)
	responseCode=$(echo "$resticGithub" | grep "HTTP/" | awk '{print $2}')
	ratelLimits=$(echo "$resticGithub" | grep "X-RateLimit-" | head -n 3)
	remaining=$(echo "${ratelLimits}" | grep "X-RateLimit-Remaining:" | cut -d":" -f2)
	resets=$(echo "${ratelLimits}" | grep "X-RateLimit-Reset:" | cut -d":" -f2)
	timeNow=$(date +%s)
	resetSeconds=$(expr $resets - $timeNow );
	resetMinutes=$(expr $resetSeconds / 60 + 1);

	if [ "$responseCode" != "200" ];
	then
		echo -e "\033[91mThere was a problem downloading Restic from Github!\033[0m"
		echo -e "We got a response code of $responseCode"
		if [ "$remaining" -eq "0" ];
		then
			echo -e "\033[33mYou have $remaining requests to Github this hour, resets in about $resetMinutes minutes \033[0m"
			echo -e "Please try again after $resetMinutes minutes pass";
		fi
		echo -e "Or you can manually try to download and install from here: https://github.com/restic/restic/releases"
		exit 1;
	fi

	downloadUrl="https://github.com/restic/restic/releases/download/v"${resticVersion}"/restic_"${resticVersion}"_"$(osFlavour)"_"$(osType)".bz2"
	echo -e "\033[36mDownloading '$downloadUrl' to restic.bz2... \033[0m"
	wget -O restic.bz2 $downloadUrl -q --show-progress
	
	echo -e "\033[36mExtracting restic.bz2... \033[0m"
	bzip2 -d restic.bz2
	
	echo -e "\033[36mMoving it to ${installPath}/restic \033[0m"
	mv restic ${installPath}/restic
	
	echo -e "\033[36mMaking ${installPath}/restic executable \033[0m"
	chmod +x ${installPath}/restic

	echo -e "\033[32mrestic has been installed, you can now call it in your terminal like this: \033[0m\n"
	echo -e "$ restic\n"

	if [ -n "$(which crontab)" ]
	then
		while true; do
			read -p $'\033[33mDo you like to install a cron entry for auto updating restic? [Y/n]\033[0m: ' answer 
			case $answer in
				[Yy]* ) installCrontab; break;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes or no.";;
			esac
		done
	fi
}

# intro
if [ -n "$(which restic)" ]
then
	echo -e "\033[33mlooks like restic is already installed: \033[0m\n"
	echo -e "Install path: "$(which restic)
	echo -e "You can now call it in your terminal like this;"
	echo -e "$ restic\n"
	
	while true; do
		read -p $'\033[33mrestic is already installed, do you want to update it? [Y/n]\033[0m: ' answer 
		case $answer in
			[Yy]* ) update; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
fi

# do you install it
if [ ! -n "$(which restic)" ]
then
	while true; do
		read -p $'\033[33mIt seems restic is not installed. Do you want to install it? [Y/n]\033[0m: ' answer 
		case $answer in
			[Yy]* ) install; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	
	if [ ! -n "$(which restic)" ]
	then
		# Show error
		echo -e "\033[91mError: restic is required and could not be installed \033[0m"
		echo -e "\033[91mPlease try downloading and installing it manually or compile it by source: \033[0m\n"
		echo -e "https://github.com/restic/restic/releases\n\n"
		exit 1;
	fi  
fi
