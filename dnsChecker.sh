#!/usr/bin/env bash

# --------------------------------------------------------------
# This script aims to facilitate the dns verification for a
# large amount of domains.
# It is distributed under GNU GPLv3.0 License, if you add
# modification to this script feels free to open a pull request.
# See https://github.com/luannbertaud/MassDNSChecker
# Script version: v1.0.0
# --------------------------------------------------------------

targetIP="00.00.000.00"
domainsFile="./domains.txt"

progressBarScale=40

domainNb=$(wc -l $domainsFile | awk '{print $1}')
domainIdx=0


displayProgress() {
    progress=$(($1 * $progressBarScale / $domainNb))
    missing=$(($progressBarScale - $progress))

    printf '['
    for run in $(seq $progress); do printf '#'; done
    for run in $(seq $missing); do printf ' '; done
    printf "] $(($progress * 100 / $progressBarScale))%%"
}

removeProgress() {
    scale=$(($progressBarScale+7))

    printf '\r'
    for run in $(seq $scale); do printf ' '; done
    printf '\r'
}

while IFS= read -r dom; do
    displayProgress $domainIdx
    if [ "$(dig +short $dom)" = "$targetIP"  ];
    then
        removeProgress
        printf "\U1F7E2 $dom\n"
    else
        removeProgress
        printf "\U1F534 $dom\n"
    fi
    domainIdx=$(($domainIdx + 1))
done < $domainsFile