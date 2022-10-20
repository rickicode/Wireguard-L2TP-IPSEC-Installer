#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/env.sh

if [[ ! -e $SECRETSFILE ]] || [[ ! -r $SECRETSFILE ]] || [[ ! -w $SECRETSFILE ]]; then
    echo "$SECRETSFILE is not exist or not accessible (are you root?)"
    exit 1
fi

unset PSK

while [[ -z "$PSK" ]];
do
    read -p "Enter preferred IPsec pre-shared key (PSK) : " PSK
    echo
done

# comment existing PSK
sed -i -e "/[[:space:]]\+PSK[[:space:]]\+/s/^/# /" $SECRETSFILE

echo -e "\n%any %any : PSK \"$PSK\"" >> $SECRETSFILE

echo "$SECRETSFILE updated!"


unset DOMAIN

while [[ -z "$DOMAIN" ]];
do
    read -p "Enter domain name : " DOMAIN
    echo
done
rm -rf /usr/local/etc/wgtp/domain.txt
echo -e $DOMAIN >> /usr/local/etc/wgtp/domain.txt
