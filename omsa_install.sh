#!/bin/bash

VERS="v2.0"

# Clear screen
clear

# Error Trapping with Cleanup
errexit() {
  # Draw 5 lines of + and message
  for i in {1..5}; do echo "+"; done
  echo -e "\e[91mError raised! Cleaning Up and Exiting.\e[39m"

  # Dirty Exit
  exit 1
}

# Phase Header
phaseheader() {
  echo
  echo -e "\e[32m=======================================\e[39m"
  echo -e "\e[35m- $1..."
  echo -e "\e[32m=======================================\e[39m"
}

# Phase Footer
phasefooter() {
  echo -e "\e[32m=======================================\e[39m"
  echo -e "\e[35m $1 Completed"
  echo -e "\e[32m=======================================\e[39m"
  echo
}

# Intro/Outro Header
inoutheader() {
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo " Dell OMSA Installer Script $VERS"
  echo
  echo " by DocDrydenn"
  echo

  if [[ "$DEBUG" = "1" ]]; then echo -e "\e[5m\e[96m++ DEBUG ENABLED - SIMULATION ONLY ++\e[39m\e[0m"; echo; fi
}

# Intro/Outro Footer
inoutfooter() {
  echo -e "\e[32m=================================================="
  echo -e "==================================================\e[39m"
  echo
}

# Error Trap
#trap 'errexit' ERR

# Setup Variables
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#BUILD=0
DEBUG=0
#STATIC=0
USAGE=0

# Parse Commandline Arguments
([ "$1" = "d" ] || [ "$1" = "-d" ]) && DEBUG=1
([ "$2" = "d" ] || [ "$2" = "-d" ]) && DEBUG=1
([ "$3" = "d" ] || [ "$3" = "-d" ]) && DEBUG=1

([ "$1" = "-h" ] || [ "$1" = "h" ]) && USAGE=1
([ "$2" = "-h" ] || [ "$2" = "h" ]) && USAGE=1
([ "$3" = "-h" ] || [ "$3" = "h" ]) && USAGE=1
([ "$4" = "-h" ] || [ "$4" = "h" ]) && USAGE=1

# Opening Intro
inoutheader
inoutfooter

if [ $USAGE -eq 1 ]
then
  echo " Usage:  ./omsa_install.sh [-dh]"
  echo
  echo "    -h | h    - Display (this) Usage Output"
  echo "    -d | d    - Enable Debug (Simulation-Only)"
  echo
inoutheader
inoutfooter
  exit 0
fi

# Check for curl
if [[ $(which curl &>/dev/null; echo $?) != "0" ]] # Production
then
  echo "Warning: CURL not found."
  echo
  echo "This script uses CURL to check for updates."
  echo
  read -r -p "Do you want to continue without checking? (not recommended) [y/N] " response
  curlresponse=${response,,}
  if [[ $curlresponse =~ ^(no|n| ) ]] || [[ -z $curlresponse ]]
  then
    echo
    echo "Note: This script can attempt to install CURL and try again."
    echo
    read -r -p "Would you like to install CURL and try again? (recommended) [Y/n] " response
    installresponse=${response,,}
    if [[ $installresponse =~ ^(yes|y| ) ]] || [[ -z $installresponse ]]
    then
      echo
      echo "Attempting to install CURL..."
      echo
      apt install curl -y
      echo
      echo "Restarting script..."
      echo
      exec $0
    else
      echo
      echo "Script Aborted."
      exit 0
    fi
  else
    echo
    echo "Continuing..."
    sleep 3
  fi
else
  # New Version Notification/Prompt
  LVER="$(curl -sI "https://github.com/DocDrydenn/omsa_install/releases/latest" | grep -Po 'tag\/\K(v\S+)')"

  if [[ -z "$LVER" ]]
  then
    echo "Online Version check failed. Continuing..."
    sleep 3
  else
    if [[ "$VERS" != "$LVER" ]]
    then
      echo -e "\e[5m\e[44m++ New Version Detected ++\e[39m\e[0m"
      echo
      echo " $VERS - Current"
      echo " $LVER - Online"
      echo
      read -r -p "Do you want to continue anyway? (not recommended) [y/N] " response
      response=${response,,}
      if [[ $response =~ ^(no|n| ) ]] || [[ -z $response ]]
      then
        echo
        echo "Script Aborted."
        exit 0
      else
        echo
        echo "Continuing..."
        sleep 3
      fi
    fi
  fi
fi


#===========================================================================================================================================
### Start Phase 1
PHASE="Old_OMSA_Purge"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Purge Everything OMSA

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - mkdir /opt/dell/srvadmin/sbin\e[39m"
  echo -e "\e[96m++ $PHASE - apt purge srvadmin-*\e[39m"
else
  echo
  mkdir /opt/dell/srvadmin/sbin
  apt purge srvadmin-*
fi

### End Phase 1
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 2
PHASE="Dell_Repo_Setup"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Setup Repo

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - deb https://linux.dell.com/repo/community/openmanage/10200/focal/ focal main > /etc/apt/sources.list.d/linux.dell.com.sources.list\e[39m"
  echo -e "\e[96m++ $PHASE - wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc\e[39m"
  echo -e "\e[96m++ $PHASE - apt-key add 0x1285491434D8786F.asc\e[39m"
  echo -e "\e[96m++ $PHASE - apt update\e[39m"
else
  echo
  echo "deb https://linux.dell.com/repo/community/openmanage/10200/focal/ focal main" > /etc/apt/sources.list.d/linux.dell.com.sources.list
  wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc
  apt-key add 0x1285491434D8786F.asc
  apt update
fi

### End Phase 2
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 3
PHASE="Special_Dependancies"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Get Special Dependancies

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-client4_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-server1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfcc/libcimcclient0_2.2.8-0ubuntu2_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/openwsman_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/multiverse/c/cim-schema/cim-schema_2.48.0-0ubuntu1_all.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfc-common/libsfcutil0_1.0.1-0ubuntu4_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/multiverse/s/sblim-sfcb/sfcb_1.4.9-0ubuntu5_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-cmpi-devel/libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libwsman-client4_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libwsman1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libwsman-server1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libcimcclient0_2.2.8-0ubuntu2_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i openwsman_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i cim-schema_2.48.0-0ubuntu1_all.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libsfcutil0_1.0.1-0ubuntu4_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i sfcb_1.4.9-0ubuntu5_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - dpkg -i libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb\e[39m"
else
  echo
  wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-client4_2.6.5-0ubuntu3_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman1_2.6.5-0ubuntu3_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/libwsman-server1_2.6.5-0ubuntu3_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfcc/libcimcclient0_2.2.8-0ubuntu2_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openwsman/openwsman_2.6.5-0ubuntu3_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/multiverse/c/cim-schema/cim-schema_2.48.0-0ubuntu1_all.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-sfc-common/libsfcutil0_1.0.1-0ubuntu4_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/multiverse/s/sblim-sfcb/sfcb_1.4.9-0ubuntu5_amd64.deb
  wget http://archive.ubuntu.com/ubuntu/pool/universe/s/sblim-cmpi-devel/libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb
  dpkg -i libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb
  dpkg -i libwsman-client4_2.6.5-0ubuntu3_amd64.deb
  dpkg -i libwsman1_2.6.5-0ubuntu3_amd64.deb
  dpkg -i libwsman-server1_2.6.5-0ubuntu3_amd64.deb
  dpkg -i libcimcclient0_2.2.8-0ubuntu2_amd64.deb
  dpkg -i openwsman_2.6.5-0ubuntu3_amd64.deb
  dpkg -i cim-schema_2.48.0-0ubuntu1_all.deb
  dpkg -i libsfcutil0_1.0.1-0ubuntu4_amd64.deb
  dpkg -i sfcb_1.4.9-0ubuntu5_amd64.deb
  dpkg -i libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb
fi

### End Phase 3
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 4
PHASE="Install_OMSA"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Install Everything!

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - apt update\e[39m"
  echo -e "\e[96m++ $PHASE - apt install srvadmin-all libncurses5 libxslt-dev\e[39m"
else
  echo
  apt update
  apt install srvadmin-all libncurses5 libxslt-dev
fi

### End Phase 4
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 5
PHASE="Restart_OMSA_Services"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Restart Service

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - /opt/dell/srvadmin/sbin/srvadmin-services.sh restart\e[39m"
else
  echo
  /opt/dell/srvadmin/sbin/srvadmin-services.sh restart
fi

# End Phase 5
phasefooter $PHASE

#===========================================================================================================================================
# Close Out
inoutheader
echo " srvadmin-services.sh Location: /opt/dell/srvadmin/sbin/"
echo
echo " Relogin to refresh paths."
echo
inoutfooter

# Clean exit of script
exit 0
