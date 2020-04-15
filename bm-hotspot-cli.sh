#!/usr/bin/env bash
# Manage Talkgroups on MMDVM-Hotspot via Brandmeister-API
# Author: Sascha 'cascha' Behrendt
# Date: 2020

APIKEY='YOUR-API-KEY'
HOTSPOT_ID='2621219'
APIURL='https://api.brandmeister.network/v1.0/repeater'
TIMESLOT='0' # 0 for Simplex Hotspot


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

function menu {
    printf "\n\
    [$(tput bold)1$(tput sgr0)]Show current Dynamic and Static TGs\n\
    [$(tput bold)2$(tput sgr0)]Drop current QSO\n\
    [$(tput bold)3$(tput sgr0)]Drop Dynamic TGs\n\
    [$(tput bold)4$(tput sgr0)]Add Static TG\n\
    [$(tput bold)5$(tput sgr0)]Drop Static TG\n\
    [$(tput bold)Q$(tput sgr0)]uit\n\n    "
    read -r -sn1 selection
    case "$selection" in
            [1]) show_tgs;;
            [2]) drop_qso;;
            [3]) drop_dynamic_tgs;;
            [4]) add_static_tg;;
            [5]) drop_static_tg;;
            [6]) bunny;;
            [qQ]) printf "\n"; exit;;
    esac
}

function show_tgs {
	echo -e "Inquire current TGs @ $HOTSPOT_ID..\n"
	curl -s $APIURL//?action\=profile\&q\=2621219 > /tmp/bm-cli.json

	echo -e "$(tput bold)Static:$(tput sgr0)"
	cat /tmp/bm-cli.json  | jq '.staticSubscriptions[].talkgroup' 2>/dev/null

	echo -e "$(tput bold)Dynamic:$(tput sgr0)"
	cat /tmp/bm-cli.json  | jq '.dynamicSubscriptions[].talkgroup' 2>/dev/null

	echo -e "$(tput bold)TimedStatic:$(tput sgr0)"
	cat /tmp/bm-cli.json  | jq 'timedSubscriptions[].talkgroup' 2>/dev/null
	echo -e "\n"
}

function drop_qso {
	echo "Dropping current QSO.."
	curl -s --user ''$APIKEY'' "$APIURL/setRepeaterDbus.php?action=dropCallRoute&slot=$TIMESLOT&q=$HOTSPOT_ID" | jq '.message' 2>/dev/null
}

function drop_dynamic_tgs {
	echo "Dropping Dynamic TGs.."
	curl -s --user ''$APIKEY'' "$APIURL/setRepeaterTarantool.php?action=dropDynamicGroups&slot=$TIMESLOT&q=$HOTSPOT_ID$" | jq '.message' 2>/dev/null
}

function add_static_tg {
	tg=""
	while [[ ! $tg =~ ^[0-9] ]]; do
		echo "Enter Talkgroup ID (Numbers Only):"
	    read tg
	done
	echo "    Adding TG $tg.."
	curl -s --user ''$APIKEY'' --data "talkgroup=$tg&timeslot=$TIMESLOT" "https://api.brandmeister.network/v1.0/repeater/talkgroup/?action=ADD&id=$HOTSPOT_ID" | jq '.message' 2>/dev/null
}

function drop_static_tg {
	tg=""
	while [[ ! $tg =~ ^[0-9] ]]; do
		echo "Enter Talkgroup ID (Numbers Only):"
	    read tg
	done
	echo "    Dropping TG $tg.."
	curl -s --user ''$APIKEY'' --data "talkgroup=$tg&timeslot=$TIMESLOT" "https://api.brandmeister.network/v1.0/repeater/talkgroup/?action=DEL&id=$HOTSPOT_ID" | jq '.message' 2>/dev/null
}

function bunny {
	printf "\nAPIURL: $APIURL\nAPIKEY: $APIKEY\nHOTSPOT_ID: $HOTSPOT_ID\nTimeslot: $TIMESLOT\n\n"
	dep_check
	ping -c 3 api.brandmeister.network
	printf "\n/)___(\ \n(='.'=)\n(\")_(\")\n"
}
dep_check
menu
