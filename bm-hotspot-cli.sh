#!/usr/bin/env bash
# Manage Talkgroups on MMDVM-Hotspot via Brandmeister-API
# Author: Sascha 'cascha' Behrendt
# Date: 2020

# Config and Variables
source api-key.txt
ver=2.0

shotspotid=2621219
stimeslot=0
sfirsttime=1

APIURL='https://api.brandmeister.network/v1.0/repeater'


function banner {
	echo $(tput setaf 3)
	echo "     ___ __  __      ___ _    ___  "
	echo "    | _ )  \/  |___ / __| |  |_ _| ";
	echo "    | _ \ |\/| |___| (__| |__ | |  ";
	echo "    |___/_|  |_|    \___|____|___| ";
	echo "	 		      $(tput sgr0)v$ver"
}

function dep_check {
	curlinstalled=$(which curl)
    if [[ "$?" == 1 ]]; then
        printf "\n\n    This Script requires curl.\n    Please install 'curl' to continue.\n\n\n"
    fi

	jqinstalled=$(which jq)
    if [[ "$?" == 1 ]]; then
        printf "\n\n    This Script requires jq.\n    Please install 'jq' to continue.\n\n\n"
		exit 0
    fi
}

function check_apikey {
	if [[ -z "$APIKEY" ]]; then
		printf "\n\n$(tput bold)API-Key Not Found.$(tput sgr0)\n"
		printf "Enter Brandmeister API-KEY in $(tput bold)api-key.txt$(tput sgr0)!\n\n\n"
		exit 0
	fi

}

function showsettings {
    printf "\n\
    $(tput bold)Saved Settings$(tput sgr0): Timeslot $(tput bold)$stimeslot$(tput sgr0) on Hotspot $(tput bold)$shotspotid$(tput sgr0)\n"
}

function menu {
    printf "\n\
    [$(tput bold)1$(tput sgr0)] Show current Dynamic and Static TGs\n\
    [$(tput bold)2$(tput sgr0)] Drop current QSO\n\
    [$(tput bold)3$(tput sgr0)] Drop Dynamic TGs\n\
    [$(tput bold)4$(tput sgr0)] Add Static TG\n\
    [$(tput bold)5$(tput sgr0)] Drop Static TG\n\
    [$(tput bold)6$(tput sgr0)] Setup\n\
    [$(tput bold)Q$(tput sgr0)] Quit\n\n    "
    read -r -sn1 menu_selection
    case "$menu_selection" in
            [1]) show_tgs;;
            [2]) drop_qso;;
            [3]) drop_dynamic_tgs;;
            [4]) add_static_tg;;
            [5]) drop_static_tg;;
            [6]) setup;;
            [7]) bunny;;
            [qQ]) printf "\n"; exit;;
    esac
}

function setup {
	#Hotspot-ID
	new_shotspotid=''
    printf "\n    $(tput setaf 3)-- Step 1 of 3: Select Hotspot-ID --$(tput sgr0)\n\
    Current Hotspot-ID is $(tput bold)$shotspotid$(tput sgr0)\n"
    while [[ ! $new_shotspotid =~ ^[0-9] ]]; do
        printf "\n    Enter new Hotspot-ID (Numbers Only): "
        read -r new_shotspotid
    done

	#Timeslot
	new_stimeslot=''
    printf "\n    $(tput setaf 3)-- Step 2 of 3: Select Timeslot-- $(tput sgr0)\n\
    Current Timeslot is $(tput bold)$stimeslot$(tput sgr0)\n"
    while [[ ! $new_stimeslot =~ ^[0-2]{1}$ ]]; do
        printf "\n    Enter new Timeslot (Numbers Only, 0 for Simplex): "
        read -r new_stimeslot
    done

	#Review
    printf "\n    $(tput setaf 3)-- Step 3 of 3: Review Settings --$(tput sgr0)\n\
    The new Settings are: Timeslot $(tput bold)$new_stimeslot$(tput sgr0) on Hotspot $(tput bold)$new_shotspotid$(tput sgr0)\n"

	#Apply Settings
    read -r -p "    Apply the above reported Settings?             [Y/n]? " apply_new_settings
    case $apply_new_settings in
        [yY][eE][sS]|[yY]|'')
        ;;
        [nN][oO]|[nN])
        printf "\n    $(tput setaf 3)Settings not saved.$(tput sgr0)\n\n"
		menu
        ;;
    esac
	savechanges
}

function savechanges {
    sed -i "s/^shotspotid.*/shotspotid=$new_shotspotid/" $0
    sed -i "s&^stimeslot.*&stimeslot=$new_stimeslot&" $0
    sed -i "s/^sfirsttime.*/sfirsttime=0/" $0

	shotspotid=$new_shotspotid
	stimeslot=$new_stimeslot
	sfirsttime=0
	printf "\n    $(tput setaf 3)Settings Saved.$(tput sgr0)\n"
	showsettings
	menu
}

function show_tgs {
	printf "Inquire current TGs @ $shotspotid $(tput bold)(TS $stimeslot)$(tput sgr0)..\n"
	curl -s $APIURL//?action\=profile\&q\=$shotspotid > /tmp/bm-cli.json

	printf "$(tput bold)\n    Static: $(tput sgr0)"
	jq '.staticSubscriptions[] | select(.slot == '"$stimeslot"' ) .talkgroup' '/tmp/bm-cli.json' | tr '\n' ' '

	printf "$(tput bold)\n    Dynamic: $(tput sgr0)"
	jq '.dynamicSubscriptions[] | select(.slot == '"$stimeslot"' ) .talkgroup' '/tmp/bm-cli.json' | tr '\n' ' '

	printf "$(tput bold)\n    TimedStatic: $(tput sgr0)"
	jq '.timedSubscriptions[] | select(.slot == '"$stimeslot"' ) .talkgroup' '/tmp/bm-cli.json' | tr '\n' ' '

	printf "\n"
	menu
}

function drop_qso {
	printf "$(tput setaf 3)Dropping current QSO..$(tput sgr0)\n\n    "
	curl -s --user ''$APIKEY:'' "$APIURL/setRepeaterDbus.php?action=dropCallRoute&slot=$stimeslot&q=$shotspotid" | jq '.message' 2>/dev/null
	menu
}

function drop_dynamic_tgs {
	printf "$(tput setaf 3)Dropping Dynamic TGs..$(tput sgr0)\n\n    "
	curl -s --user ''$APIKEY:'' "$APIURL/setRepeaterTarantool.php?action=dropDynamicGroups&slot=$stimeslot&q=$shotspotid$" | jq '.message' 2>/dev/null
	menu
}

function add_static_tg {
	tg=''
	printf "\n"
	while [[ ! $tg =~ ^[0-9] ]]; do
		printf "    Enter Talkgroup ID (Numbers Only): "
	    read tg
	done
	printf "\n$(tput setaf 3)    Adding TG $tg..$(tput sgr0)\n\n    "
	curl -s --user ''$APIKEY:'' --data "talkgroup=$tg&timeslot=$stimeslot" "https://api.brandmeister.network/v1.0/repeater/talkgroup/?action=ADD&id=$shotspotid" | jq '.message' 2>/dev/null
	menu
}

function drop_static_tg {
	tg=''
	printf "\n"
	while [[ ! $tg =~ ^[0-9] ]]; do
		printf "    Enter Talkgroup ID (Numbers Only): "
	    read tg
	done
	printf "\n$(tput setaf 3)    Dropping TG $tg..$(tput sgr0)\n\n    "
	curl -s --user ''$APIKEY:'' --data "talkgroup=$tg&timeslot=$stimeslot" "https://api.brandmeister.network/v1.0/repeater/talkgroup/?action=DEL&id=$shotspotid" | jq '.message' 2>/dev/null
	menu
}

function bunny {
	printf "\n\n    $(tput setaf 6)APIURL: $APIURL\n    APIKEY: $APIKEY\n\n    HOTSPOT_ID: $shotspotid\n    TIMESLOT: $stimeslot\n\n    FIRSTTIME: $sfirsttime$(tput sgr0)\n\n"
	dep_check
	printf "\n\n    $(tput setaf 5)/)___(\ \n    (='.'=)\n    (\")_(\")$(tput sgr0)$(tput bold) (v$ver) by Sascha 'cascha' Behrendt$(tput sgr0)\n\n"
	menu
}

dep_check
check_apikey
banner
showsettings
if [[ "$sfirsttime" == "1" ]]; then
    printf "
    Since this is the first time running this, Setup\n\
    is recommended to update initial Configuration.\n"
fi
menu
