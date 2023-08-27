#!/bin/bash

VERS="v2.9"

# Set Script Variables
SCRIPT="$(readlink -f "$0")"
SCRIPTFILE="$(basename "$SCRIPT")"
SCRIPTPATH="$(dirname "$SCRIPT")"
SCRIPTNAME="$0"
ARGS=( "$@" )
BRANCH="main"
DEBUG=0
URL='linux.dell.com/repo/community/openmanage/'
RAW_VERSION_ARRAY=()
VERSION_ARRAY=('Cancel')
#VERSION=""
RAW_BUILD_ARRAY=()
BUILD_ARRAY=('Cancel')
BUILD=""
USR_VER_URL=""
FINAL_URL=""

# Script Update Function
self_update() {
    echo "Checking for Script Updates..."
    echo
    # Check if script path is a git clone.
    #   If true, then check for update.
    #   If false, skip self-update check/funciton.
    if [[ -d "$SCRIPTPATH/.git" ]]; then
        echo "   ✓ Git Clone Detected: Checking Script Version..."
        cd "$SCRIPTPATH" || exit 1
        timeout 1s git fetch --quiet
        timeout 1s git diff --quiet --exit-code "origin/$BRANCH" "$SCRIPTFILE"
        [ $? -eq 1 ] && {
            echo "   ✗ Version: Mismatched"
            echo
            echo "Fetching Update..."
            echo
            if [ -n "$(git status --porcelain)" ];  then
                git stash push -m 'local changes stashed before self update' --quiet
            fi
            git pull --force --quiet
            git checkout $BRANCH --quiet
            git pull --force --quiet
            echo "   ✓ Update Complete. Running New Version. Standby..."
            sleep 3
            cd - > /dev/null || exit 1

            # Execute new instance of the new script
            exec "$SCRIPTNAME" "${ARGS[@]}"

            # Exit this old instance of the script
            exit 1
        }
        echo "   ✓ Version: Current"
    else
        echo "   ✗ Git Clone Not Detected: Skipping Update Check"
    fi
}

# Error Trapping with Cleanup Function
errexit() {
  # Draw 5 lines of + and message
  for i in {1..5}; do echo "+"; done
  echo -e "\e[91mError raised! Cleaning Up and Exiting.\e[39m"

  # Dirty Exit
  exit 1
}

# Version Menu
createmenu_version ()
{
  echo "Select desired version:"
  select option; do # in "$@" is the default
    if [ "$REPLY" -eq 1 ];
    then
      echo "Exiting..."
      exit 0
      break;
    elif [ "$REPLY" -ge 1 ] && [ "$REPLY" -le $# ];
    then
      #echo "You selected $option which is option $REPLY"
      USR_VER_URL=$URL$option
      #VERSION=${option%?}
      break;
    else
      echo "Incorrect Input: Select a number 1-$#"
    fi
  done
}

# Build Menu
createmenu_build ()
{
  echo "Select desired build:"
  select option; do # in "$@" is the default
    if [ "$REPLY" -eq 1 ];
    then
      echo "Exiting..."
      exit 0
      break;
    elif [ "$REPLY" -ge 1 ] && [ "$REPLY" -le $# ];
    then
      FINAL_URL=$USR_VER_URL$option
      BUILD=${option%?}
      break;
    else
      echo "Incorrect Input: Select a number 1-$#"
    fi
  done
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

# Usage Example Function
usage_example() {
  inoutheader
  inoutfooter
  echo " Usage:  ./omsa_install.sh [-dh]"
  echo
  echo "    -h | h    - Display (this) Usage Output"
  echo "    -d | d    - Enable Debug (Simulation-Only)"
  echo
  exit 0
}

# Error Trap
trap 'errexit' ERR

# Parse Commandline Arguments
{ [ "$1" = "-h" ] || [ "$1" = "h" ]; } && usage_example
{ [ "$2" = "-h" ] || [ "$2" = "h" ]; } && usage_example

{ [ "$1" = "d" ] || [ "$1" = "-d" ]; } && DEBUG=1
{ [ "$2" = "d" ] || [ "$2" = "-d" ]; } && DEBUG=1

# Opening Intro
clear
inoutheader
inoutfooter


#===========================================================================================================================================
### Start Phase 0
PHASE="Script_Self-Update"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Self Update
self_update

### End Phase 0
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 0.5
PHASE="Version-Build_Selection"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
echo "Parsing for available versions."
echo "(this can take up to 30 seconds)"
echo
# Parse RAW Dell Website
IFS=$'\n' read -r -d '' -a RAW_VERSION_ARRAY < <( wget -q $URL -O - | tr "\t\r\n'" '   "' | grep -i -o '<a[^>]\+href[ ]*=[ \t]*"[^"]\+">[^<]*</a>' | sed -e 's/^.*"\([^"]\+\)".*$/\1/g' && printf '\0' )

# Parse for Versions
for i in "${RAW_VERSION_ARRAY[@]}"
do
  [[ $i == [0-9]* ]] && [[ ${#i} -gt 2 ]] && VERSION_ARRAY+=("$i")
done

# Prompt for Desired Version
createmenu_version "${VERSION_ARRAY[@]}"

echo
echo "Parsing for available builds..."
echo "(this can take up to 30 seconds)"
echo
# Parse RAW Builds
IFS=$'\n' read -r -d '' -a RAW_BUILD_ARRAY < <( wget -q $USR_VER_URL -O - | tr "\t\r\n'" '   "' | grep -i -o '<a[^>]\+href[ ]*=[ \t]*"[^"]\+">[^<]*</a>' | sed -e 's/^.*"\([^"]\+\)".*$/\1/g' && printf '\0' )

# Parse for Builds
for i in "${RAW_BUILD_ARRAY[@]}"
do
  [[ $i == [a-z]* ]] && BUILD_ARRAY+=("$i")
done

# Prompt for Desired Build
createmenu_build "${BUILD_ARRAY[@]}"

#echo "Final URL: $FINAL_URL"
echo

### End Phase 0.5
phasefooter $PHASE

#===========================================================================================================================================
### Start Phase 1
PHASE="Old_OMSA_Purge"
phaseheader $PHASE
sleep 1
#===========================================================================================================================================
# Purge Everything OMSA

if [ $DEBUG -eq 1 ]
then
  echo -e "\e[96m++ $PHASE - [[ -f /etc/apt/sources.list.d/linux.dell.com.sources.list ]] && rm /etc/apt/sources.list.d/linux.dell.com.sources.list"
  echo -e "\e[96m++ $PHASE - mkdir -p /opt/dell/srvadmin/sbin\e[39m"
  echo -e "\e[96m++ $PHASE - apt purge srvadmin-*\e[39m"
else
  echo
  [[ -f "/etc/apt/sources.list.d/linux.dell.com.sources.list" ]] && rm /etc/apt/sources.list.d/linux.dell.com.sources.list
  [[ ! -d "/opt/dell/srvadmin/sbin" ]] && mkdir -p /opt/dell/srvadmin/sbin

  if dpkg-query -W --showformat='${Status}\n' srvadmin-*|grep "install ok installed" >/dev/null; then
    apt purge srvadmin-* -y
  fi
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
  echo -e "\e[96m++ $PHASE - deb https://$FINAL_URL $BUILD main > /etc/apt/sources.list.d/linux.dell.com.sources.list\e[39m"
  echo -e "\e[96m++ $PHASE - wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc\e[39m"
  echo -e "\e[96m++ $PHASE - apt-key add 0x1285491434D8786F.asc\e[39m"
  echo -e "\e[96m++ $PHASE - apt update\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/0x1285491434D8786F.asc\e[39m"
else
  echo
  echo "deb https://$FINAL_URL $BUILD main" > /etc/apt/sources.list.d/linux.dell.com.sources.list
  wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc
  apt-key add 0x1285491434D8786F.asc
  apt update
  rm "$SCRIPTPATH/0x1285491434D8786F.asc"
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
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libwsman-client4_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libwsman1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libwsman-server1_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libcimcclient0_2.2.8-0ubuntu2_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/openwsman_2.6.5-0ubuntu3_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/cim-schema_2.48.0-0ubuntu1_all.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libsfcutil0_1.0.1-0ubuntu4_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/sfcb_1.4.9-0ubuntu5_amd64.deb\e[39m"
  echo -e "\e[96m++ $PHASE - rm $SCRIPTPATH/libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb\e[39m"

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
  rm "$SCRIPTPATH/libwsman-curl-client-transport1_2.6.5-0ubuntu3_amd64.deb"
  rm "$SCRIPTPATH/libwsman-client4_2.6.5-0ubuntu3_amd64.deb"
  rm "$SCRIPTPATH/libwsman1_2.6.5-0ubuntu3_amd64.deb"
  rm "$SCRIPTPATH/libwsman-server1_2.6.5-0ubuntu3_amd64.deb"
  rm "$SCRIPTPATH/libcimcclient0_2.2.8-0ubuntu2_amd64.deb"
  rm "$SCRIPTPATH/openwsman_2.6.5-0ubuntu3_amd64.deb"
  rm "$SCRIPTPATH/cim-schema_2.48.0-0ubuntu1_all.deb"
  rm "$SCRIPTPATH/libsfcutil0_1.0.1-0ubuntu4_amd64.deb"
  rm "$SCRIPTPATH/sfcb_1.4.9-0ubuntu5_amd64.deb"
  rm "$SCRIPTPATH/libcmpicppimpl0_2.0.3-0ubuntu2_amd64.deb"
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
  apt install srvadmin-all libncurses5 libxslt-dev -y
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
echo "Service Control: /opt/dell/srvadmin/sbin/srvadmin-services.sh"
echo
echo "Web Access: https://localhost:1311"
echo
echo "Note: Re-login needed before user paths will refresh."
echo
inoutfooter

# Clean exit of script
exit 0
