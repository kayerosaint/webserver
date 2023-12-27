#!/bin/bash

SSLCF=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SSLCF/{v=t($2)};END{printf "%s\n",v}' ./.env)
SertDir=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SertDir/{v=t($2)};END{printf "%s\n",v}' ./.env)
SSLCertificateFile="$SertDir/$SSLCF"
CHAT_ID=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^CHAT_ID/{v=t($2)};END{printf "%s\n",v}' ./.env)
API=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^API/{v=t($2)};END{printf "%s\n",v}' ./.env)

date=$(openssl x509 -noout -text -in $SSLCertificateFile | grep After | cut -d":" -f 2- | awk -F'GMT' '{print substr($1,2)'} | awk '{print $1 " " $2 " " $4}') && date2=$(date -d"$date" +%Y%m%d) && date3=$(date +%Y%m%d) && let DIFF=($(date +%s -d $date2) - $(date +%s -d $date3))/86400 && if [ "$DIFF" -le "10" ]; then
curl --data "chat_id=$CHAT_ID&text=WARNING from server $HOSTNAME ! Certificates will expired soon! You have $DIFF days remaining! Visit https://manage.sslforfree.com/ for renew" https://api.telegram.org/bot$API/sendMessage? &>/dev/null ; fi

