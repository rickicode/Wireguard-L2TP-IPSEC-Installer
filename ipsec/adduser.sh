#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/env.sh

if [[ ! -e $CHAPSECRETS ]] || [[ ! -r $CHAPSECRETS ]] || [[ ! -w $CHAPSECRETS ]]; then
    echo "$CHAPSECRETS is not exist or not accessible (are you root?)"
    exit 1
fi

NOTADDUSER="no"
ANSUSER="yes"

datenow=$(date +"%Y-%m-%d")



if [[ $# -gt 0 ]]; then
    LOGIN="$1"
fi

while [[ -z "$LOGIN" ]];
do
    read -p "Username: " LOGIN
done

unset PASSWORD

while [[ -z "$PASSWORD" ]];
do
    read -p "Password: " PASSWORD
done

read -p 'Expired (days) : ' EXPIRED
while [[ ! $EXPIRED =~ ^-?[0-9]+$ ]]; do
    echo "Woy Salah!"
    read -p 'Enter Expired Day : ' EXPIRED
done

DELETED=0
EXP=$(date +%d-%m-%Y -d "$datenow + $EXPIRED day")


#$DIR/checkuser.sh $LOGIN

cekuser=$(grep -P "^$LOGIN\s+" $CHAPSECRETS)
if [[ ! -z "$cekuser" ]]; then
    echo "Akun $LOGIN Sudah ada."
    exit
fi

# if [[ $? -eq 0 ]]; then
# 	NOTREM="no"
# 	read -p "User '$LOGIN' already exists. Do you want to remove existing user? [no] " ANSREM
# 	: ${ANSREM:=$NOTREM}

# 	if [ "$NOTREM" == "$ANSREM" ]; then
# 		unset LOGIN PASSWORD
# 		if [[ $# -gt 0 ]]; then
# 			# exit, if script is called with params
# 			ANSUSER=$NOTADDUSER
# 		else
# 			read -p "Would you want to add another user? [no] " ANSUSER
# 			: ${ANSUSER:=$NOTADDUSER}
# 			unset LOGIN
# 		fi
# 		continue
# 	else
# 		$DIR/deluser.sh $LOGIN
# 		DELETED=1
# 	fi
# fi

echo -e "# BEGIN_PEER $LOGIN EXP $EXP" >> $CHAPSECRETS
echo -e "$LOGIN\t    *\t    $PASSWORD\t    *" >> $CHAPSECRETS
echo -e "# END_PEER $LOGIN" >> $CHAPSECRETS


if [ $DELETED -eq 0 ]; then
    echo "$CHAPSECRETS has been updated!"
fi

PSK=$(sed -n "s/^[^#]\+[[:space:]]\+PSK[[:space:]]\+\"\(.\+\)\"/\1/p" $SECRETSFILE)
echo $PSK

mkdir -p "$DIR/akun/$LOGIN"
DISTFILE=$DIR/akun/$LOGIN/setup.sh
cp -rf $DIR/setup.sh.dist "$DISTFILE"
sed -i -e "s@_PSK_@$PSK@g" "$DISTFILE"
sed -i -e "s@_SERVERLOCALIP_@$LOCALPREFIX.1@g" "$DISTFILE"

DISTFILE=$DIR/akun/$LOGIN/ipsec.conf
cp -rf $DIR/ipsec.conf.dist "$DISTFILE"
sed -i -e "s@LEFTIP@%any@g" "$DISTFILE"
sed -i -e "s@LEFTPORT@%any@g" "$DISTFILE"
sed -i -e "s@RIGHTIP@$IP@g" "$DISTFILE"
sed -i -e "s@RIGHTPORT@1701@g" "$DISTFILE"

DISTFILE=$DIR/akun/$LOGIN/xl2tpd.conf
cp -rf $DIR/client-xl2tpd.conf.dist "$DISTFILE"
sed -i -e "s@REMOTEIP@$IP@g" "$DISTFILE"

DISTFILE=$DIR/akun/$LOGIN/options.xl2tpd
cp -rf $DIR/client-options.xl2tpd.dist "$DISTFILE"
sed -i -e "s@_LOGIN_@$LOGIN@g" "$DISTFILE"
sed -i -e "s@_PASSWORD_@$PASSWORD@g" "$DISTFILE"

cp -rf $DIR/connect.sh.dist "$DIR/akun/$LOGIN/connect.sh"
cp -rf $DIR/disconnect.sh.dist "$DIR/akun/$LOGIN/disconnect.sh"

chmod +x "$DIR/akun/$LOGIN/setup.sh" "$DIR/akun/$LOGIN/connect.sh" "$DIR/akun/$LOGIN/disconnect.sh"

USERNAME=${SUDO_USER:-$USER}
chown -R $USERNAME:$USERNAME $DIR/akun/$LOGIN/
echo
echo "Directory $DIR/$LOGIN with client-side installation script has been created."


IP=$(wget -4qO- "http://whatismyip.akamai.com/")

#PSK=$(grep '^%any %any :' /etc/ipsec.secrets | cut -d '"' -f 2)

DOMAIN=$(cat /usr/local/etc/wgtp/domain.txt)
echo $DOMAIN
	cat << EOF > /root/akun/l2tp/"$LOGIN".txt
Terimakasih Telah Menggunakan Layanan HIJITOKO
====== Informasi Akun ======
Address		: $IP / $DOMAIN
Ipsec		: $PSK
Username    : $LOGIN
Password	: $PASSWORD
Masa Aktif	: $EXP
====== Informasi Akun ======
Wajib memasukan Ipsec/PreShared key/Tunnel Password, jika tidak VPN tidak akan berjalan.
Terimakasih dan jangan lupa bintang 5 nya ya.
EOF


echo
echo
echo
clear
echo "Terimakasih Telah Menggunakan Layanan HIJITOKO"
echo "====== Informasi Akun ======"
echo "Address		: $IP / $DOMAIN"
echo "Ipsec		: $PSK"
echo "Username	: $LOGIN"
echo "Password	: $PASSWORD"
echo "Masa Aktif	: $EXP"
echo "====== Informasi Akun ======"
echo "Wajib memasukan Ipsec/PreShared key/Tunnel Password, jika tidak VPN tidak akan berjalan."
echo "Terimakasih dan jangan lupa bintang 5 nya ya."
echo
echo
echo

exit

# if [[ $# -eq 0 ]]; then
# 	echo
# 	read -p "Would you want to add another user? [no] " ANSUSER
# 	: ${ANSUSER:=$NOTADDUSER}
# 	unset LOGIN
# else
# 	ANSUSER=$NOTADDUSER
# fi
