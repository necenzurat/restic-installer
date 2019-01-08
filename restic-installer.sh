#!/bin/bash
#
# restic install script
#
# @version	0.1.0
# @date		2014-07-30
# @license	DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE


# Set environment
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# epic logo incomming
echo -e "\033[91m    ___  _______________________ \033[0m"
echo -e "\033[91m   / _ \/ __/ __/_  __/  _/ ___/ \033[0m"
echo -e "\033[91m  / , _/ _/_\ \  / / _/ // /__   \033[0m"
echo -e "\033[91m /_/|_/___/___/ /_/ /___/\___/   \033[0m \033[32mInstaller \033[0m"
echo -e "==========================================="
echo -e "\nFast, secure, efficient backup program \n\nWeb: https://restic.net/\nGithub: https://github.com/restic/restic\nRTFM: https://restic.readthedocs.io/en/stable/"
echo -e "===========================================\n"

if [ "$UID" != "0" ]; then
	sudoPath=$(command -v sudo)
    if [ ! -w "${sudoPath}" ]; then
        echo -e "\033[32mThis installer requires needs to be run as with sudo\033[0m"
        wget --quiet https://github.com/necenzurat/restic-installer/raw/master/restic-installer.sh 
		echo -e "You can run it like:"
		echo -e "$ sudo bash restic-installer.sh\n"
        exit 1
   else
        echo -e "\033[91msudo was not found, please run this installer as root!\033[0m"
        exit 1
   fi 
fi


function update (){

	echo -e "\033[32mHint: restic can self update, you just need to execute this command: \033[0m\n"
	echo -e "$ restic self-update\n"
	echo -e "===========================================\n"

	installedPath=$(command -v restic)
	${installedPath} self-update
}

function os_flavour ()
{
	echo $(uname | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/")
}

function os_type ()
{
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

if [[ $(os_type) == "unsupported" ]]; then
	echo -e "\033[91m"$(uname -m)" is unsuported by this installer, try installing it from source. \033[0m"
	echo -e "\033[91mPlease try downloading and installing it manually or compile it by source: \033[0m"
	echo -e "https://github.com/restic/restic/releases\n\n"
	exit 1;
fi

function get_restic_release(){
	echo $(wget -q -O- https://api.github.com/repos/restic/restic/releases/latest | grep tag_name | cut -d '"' -f 4  | cut -d 'v' -f 2)
}

function install_crontab () {
	echo -e "\n# Dynamically added by restic installer\n# It can be removed if auto update is no longer necessary\n0 0 * * *  root  ${installPath}/restic self-update > /var/log/restic-update.log 2>&1" >> /etc/crontab;
	echo -e "A cron job has been set in /etc/crontab, and the output will be sent to /var/log/restic-update.log"
}

# Install function
function install() {
		flavor=$(os_flavour)
		cpu_type=$(os_type)
		restic_version=$(get_restic_release)

		# fix for low privilege... plebs
		installPath="/usr/bin";
		if [ ! -w "${installPath}" ]; 
		then 
			installPath="/usr/local/bin";	
		fi

		url="https://github.com/restic/restic/releases/download/v"${restic_version}"/restic_"${restic_version}"_"${flavor}"_"${cpu_type}".bz2"
 
        # this, right here is awesome and took a shitty long time to write
        # fucking bash
        # please refactor if you know bash
        githubHeaders=$(wget --server-response --spider --quiet "https://api.github.com/repos/restic/restic/releases/latest" 2>&1)
        responseCode=$(echo "$githubHeaders" | awk 'NR==1{print $2}')
        ratelLimits=$(echo "$githubHeaders" | grep X-RateLimit- | head -n 3)
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
			echo -e "Or you can manualy try to download and install from here: https://github.com/restic/restic/releases"
			exit 1;
		fi

 		echo -e "\033[36mDownloading to restic.bz2... \033[0m"
		wget --quiet -O restic.bz2 $url
		
		echo -e "\033[36mExtracting restic.bz2... \033[0m"
		bzip2 -d restic.bz2
		
		echo -e "\033[36mMoving it to ${installPath}/restic \033[0m"
		mv restic ${installPath}/restic
		
		echo -e "\033[36mMaking ${installPath}/restic executable \033[0m"
		chmod +x ${installPath}/restic

		echo -e "\033[32mrestic has been installed, you can now call it in your terminal like this: \033[0m\n"
		echo -e "$ restic\n"


		if [ -n "$(command -v crontab)" ]
		then
			while true; do
				read -p $'\033[33mDo you like to install a cron entry for auto updating restic? [Y/n]\033[0m: ' answer 
			    case $answer in
			        [Yy]* ) install_crontab; break;;
			        [Nn]* ) exit;;
			        * ) echo "Please answer yes or no.";;
			    esac
			done
		fi
}

# 1st part
if [ -n "$(command -v restic)" ]
then
	echo -e "\033[33mlooks like restic is already installed: \033[0m\n"
	echo -e "Install path: "$(command -v restic)
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

# install part
if [ ! -n "$(command -v restic)" ]
then
	while true; do
		read -p $'\033[33mIt seems restic is not installed. Do you want to install it? [Y/n]\033[0m: ' answer 
	    case $answer in
	        [Yy]* ) install; break;;
	        [Nn]* ) exit;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done
	
	if [ ! -n "$(command -v restic)" ]
	then
	    # Show error
	    echo -e "\033[91mError: restic is required and could not be installed \033[0m"
		echo -e "\033[91mPlease try downloading and installing it manually or compile it by source: \033[0m\n"
		echo -e "https://github.com/restic/restic/releases\n\n"
		exit 1;
	fi	
fi
