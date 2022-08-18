#!/usr/bin/env bash

# --------------------------------------------------------------
# This script aims to facilitate the dns verification for a
# large amount of domains.
# It is distributed under GNU GPLv3.0 License, if you add
# modification to this script feels free to open a pull request.
# See https://github.com/luannbertaud/MassDNSChecker
# Script version: v1.1.0
# --------------------------------------------------------------

targetIP="00.00.000.00"
domainsFile="./domains.txt"

progressBarScale=40
recheckDelay=2

domainNb=$(wc -l $domainsFile | awk '{print $1}')
domainIdx=0
failedDomains=""
okIcon="\U1F7E2"
koIcon="\U1F534"
dnsIcon="\U1F30D"
warnIcon="\U1F6A7"
partyIcon="\U1F389"
currentIcon="\U1F7E0"

displayProgress() {
    progress=$(($1 * $progressBarScale / $domainNb))
    missing=$(($progressBarScale - $progress))

    printf '['
    for _ in $(seq $progress); do printf '#'; done
    for _ in $(seq $missing); do printf ' '; done
    printf "] $(($progress * 100 / $progressBarScale))%%"
}

removeProgress() {
    scale=$(($progressBarScale+7))

    printf '\r'
    for _ in $(seq $scale); do printf ' '; done
    printf '\r'
}

removeLines() {
    echo -en "\033[$1A\033[2K\r"
}

conditionalInput() {
    printf "$@\n";
    read -p "> " uInput

    if [[ "$uInput" = "" ]];
    then
        echo -e "\033[1A\033[2K> Y"
    fi

    if [[ "$uInput" = "y" || "$uInput" = "" ]];
    then
        uInput="Y"
    fi
}

uInput=""
conditionalInput "$dnsIcon About to test $domainNb domain$([[ $domainNb < 2 ]] && echo '' || echo 's') to match $targetIP, continue ? (Y/n)"
if [ ! $uInput = "Y" ];
then
    exit
fi

#
# Trying dns resolution on all domains
#

for _ in $(seq $(($progressBarScale+7))); do printf '='; done
echo ""

while IFS= read -r dom;
do
    printf "$currentIcon $dom\n"
    displayProgress $domainIdx
    if [ "$(dig +short $dom)" = "$targetIP"  ];
    then
        removeProgress
        removeLines 1
        printf "$okIcon $dom\n"
    else
        removeProgress
        removeLines 1
        printf "$koIcon $dom\n"
        failedDomains+="$dom\n"
    fi
    domainIdx=$(($domainIdx + 1))
done < $domainsFile

#
# Retrying failed domains
#

while [ ! $failedDomains = "" ];
do
    failedDomainsNb=$(($(echo -e $failedDomains | wc -l) - 1))
    for _ in $(seq $(($progressBarScale+7))); do printf '='; done
    printf "\n$warnIcon $failedDomainsNb domain$([[ $failedDomainsNb < 2 ]] && echo '' || echo 's') failed, retrying ... $warnIcon\n"

    failedDomainsOg=$failedDomains
    failedDomains=""
    domainIdx=0
    for dom in $(echo -e $failedDomainsOg)
    do
        printf "$currentIcon $dom"
        sleep $recheckDelay
        if [ "$(dig +short $dom)" = "$targetIP"  ];
        then
            printf "\r$okIcon $dom\n"
        else
            printf "\r$koIcon $dom\n"
            failedDomains+="$dom\n"
        fi
        domainIdx=$(($domainIdx + 1))
    done
    
    if [ ! $failedDomains = "" ];
    then
        removeLines $(($failedDomainsNb + 2))
    fi
done

if [  "$failedDomains" = "" ];
then
    for run in $(seq $(($progressBarScale+7))); do printf '='; done
    printf "\n$partyIcon All $domainNb domain$([[ $domainNb < 2 ]] && echo '' || echo 's') or pointing to $targetIP ! $partyIcon\n"
fi