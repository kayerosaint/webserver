#!/bin/bash

# Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan
Color_Off='\033[0m'       # Reset

# Directives #

ip_ftp=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^ip_ftp/{v=t($2)};END{printf "%s\n",v}' ./.env)

# 1C version
version=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^version/{v=t($2)};END{printf "%s\n",v}' ./.env)

# For apache conf
ServerName=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^ServerName/{v=t($2)};END{printf "%s\n",v}' ./.env)
SSLCF=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SSLCF/{v=t($2)};END{printf "%s\n",v}' ./.env)
SSLCAF=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SSLCAF/{v=t($2)};END{printf "%s\n",v}' ./.env)
SSLKF=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SSLKF/{v=t($2)};END{printf "%s\n",v}' ./.env)
SertDir=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SertDir/{v=t($2)};END{printf "%s\n",v}' ./.env)
SertKeyDir=$(awk -F '=' 'function t(s){gsub(/[[:space:]]/,"",s);return s};/^SertKeyDir/{v=t($2)};END{printf "%s\n",v}' ./.env)

SSLCertificateFile="$SertDir/$SSLCF"
SSLCACertificateFile="$SertDir/$SSLCAF"
SSLCertificateKeyFile="$SertKeyDir/$SSLKF"

# Other
CUR_DIR=$(pwd)


# Logs
exec 2>logs+errors

# Ssh enable
echo -e "$Cyan \n SSH Enable $Color_Off"
chkconfig sshd on;
service sshd start;
sleep 1;

# Net-tools
echo -e "$Cyan \n Install net-tools $Color_Off" ;
if ! yum list installed | grep net-tools >&/dev/null ; then
    sudo yum -y install net-tools;
else
    echo -e "$Green \n net-tools already installed $Color_Off" && sleep 1
fi

# Update system
echo -e "$Cyan \n System update, pls wait $Color_Off"
yum update -y >/dev/null ;
yum -y install epel-release &>/dev/null ;

# Create users?
echo -e "$Cyan \n Create new user? $Color_Off"
  echo "1 - yes, 2 - no"
  read new_user
  case $new_user in
    1)
    sleep 2
    echo -e "$Yellow \n Enter new user name!: $Color_Off"
    read -p "Username: " user
    sudo useradd -m $user
    echo -e "$Yellow \n Enter new user password!: $Color_Off"
    read -s -p "User password: " u_pswd
    sudo passwd $u_pswd ;;
    2)
    echo -e "$Red \n aborted $Color_Off"
    sleep 1 ;;
    *)
    echo -e "$Red \n error $Color_Off"
    sleep 1
  esac

# Wheel group?
echo -e "$Cyan \n Add selected user to group WHEEL? $Color_Off"
  echo "1 - yes, 2 - no"
  read wheel_group
  case $wheel_group in
    1)
    sleep 2
    sed 's/:.*//' /etc/passwd
    echo -e "$Yellow \n Enter the name of the user who be added to the WHEEL group!: $Color_Off"
    read -p "Username: " user_1
    sudo usermod -a -G wheel $user_1
    echo -e "$Yellow \n added $Color_Off" ;;
    2)
    echo -e "$Red \n aborted $Color_Off"
    sleep 1 ;;
    *)
    echo -e "$Red \n error $Color_Off"
    sleep 1
  esac

: <<'END'
# pv install
echo -e "$Cyan \n Install PV $Color_Off" ;
if ! yum list | grep pv.x86_64 >&/dev/null ; then 
    yum -y install pv ;
else
    echo -e "$Green \n PV already installed $Color_Off" && sleep 1
fi
END

# Install midnight commander
echo -e "$Cyan \n MC install $Color_Off"
if ! sudo rpm -qa | grep mc-4.* > /dev/null ; then
  yum install -y mc
else
  echo -e "$Green \n MC already installed $Color_Off"
fi

# Install vim
echo -e "$Cyan \n VIM WGET install $Color_Off"
if ! sudo rpm -qa | grep vim > /dev/null && ! sudo rpm -qa | grep wget > /dev/null ; then
    yum install -y vim wget
else
  echo -e "$Green \n vim, wget already installed $Color_Off" && sleep 1
fi

# Install htop bzip
echo -e "$Cyan \n htop bzip2 install $Color_Off"
if ! sudo rpm -qa | grep htop-* > /dev/null && ! sudo rpm -qa | grep bzip2* > /dev/null ; then
  yum -y install htop bzip2 pv
else
  echo -e "$Green \n htop bzip2 already installed $Color_Off" && sleep 1
fi

# Install apache
echo -e "$Cyan \n apache install $Color_Off"
if ! sudo rpm -qa | grep httpd-* > /dev/null ; then
  yum -y install httpd
else
  echo -e "$Green \n apache already installed $Color_Off" && sleep 1
fi

# Start apache
systemctl start httpd.service && systemctl enable httpd.service ;

# Open firewall
echo -e "$Cyan \n Open firewall $Color_Off" && sleep 0.5;
if ! firewall-cmd --list-all | grep -q "http"; then 
    firewall-cmd --permanent --zone=public --add-service=http && echo -e "$Green \n service=http $Color_Off" && firewall-cmd --reload ;
else
    echo -e "$Green \n service http exist $Color_Off" && sleep 1
fi

if ! firewall-cmd --list-all | grep -q "https"; then 
    firewall-cmd --permanent --zone=public --add-service=https && echo -e "$Green \n service=https $Color_Off" && firewall-cmd --reload ;
else
    echo -e "$Green \n service https exist $Color_Off" && sleep 1
fi

# Remove 1c
echo -e "$Cyan \n Remove old 1C version ? $Color_Off"
echo "1 - yes, 2 - no"
read remove
case $remove in
  1) 
    echo -e "$Red \n Attention! The old version of 1C will be deleted, you have 10 seconds to cancel this action, press CTRL+C $Color_Off" ;
    for i in {9..1}; do
      echo -ne "$i\r"
      sleep 1
    done
    yum remove 1c* -y >/dev/null && rm -rf /opt/1cv8 ;;
  2)
    echo -e "$Red \n aborted $Color_Off"
    sleep 1 ;;
  *)
    echo -e "$Red \n error $Color_Off"
    sleep 1 ;;
esac

# Install 1C
echo -e "$Cyan \n Install 1C ? $Color_Off"
echo "1 - yes, 2 - no"
  read inst
  case $inst in
    1)
    if ! [ -e /tmp/$ip_ftp/upload/setup-full-$version-x86_64.run ] ; then
      retries=0
      max_retries=3
      while [ $retries -lt $max_retries ]
      do 
          echo -e "$Yellow \n For download 1C version $version from FTP ($ip_ftp) please enter credentials! $Color_Off" && sleep 2
          echo -e "$Yellow \n Enter FTP user: $Color_Off"
          read -p user": " ftpuser
          echo -e "$Yellow \n Enter password for $ftpuser: $Color_Off"
          read -p password": " -s pass
          if wget --timeout=3 --tries=2 ftp://$ftpuser:$pass@$ip_ftp ; then
              rm -rf /tmp/10.* $CUR_DIR/index.*
              echo -e "$Green \n success connection, begin downloading...$Color_Off" && wget --progress=dot -m -P /tmp ftp://$ftpuser:$pass@$ip_ftp:/upload/setup-full-$version-x86_64.run 2>&1 | awk 'NF>2 && $(NF-2) ~ /%/{printf "\r %s",$(NF-2)} END{print "\r    "}'
              break
          else
              calc=$((max_retries-1 - retries)) && echo -e "$Red \n wrong credentials, you have $calc attempts left $Color_Off" && retries=$((retries+1))
          fi
      done

      for dir in /opt/1cv8/x86_64/8.3.*; do
      if [[ ! -d "$dir" ]]; then
        cd /tmp/$ip_ftp/upload/ && sudo chmod 744 setup-full-$version-x86_64.run && sudo ./setup-full-$version-x86_64.run --mode unattended --enable-components server,ws
        echo -e "$Green \n Success installation! $Color_Off"
      else  
        echo -e "$Green \n 1c already installed $Color_Off" && sleep 1
      fi
      done

    else
      for dir in /opt/1cv8/x86_64/8.3.*; do
      if [[ ! -d "$dir" ]]; then
        cd /tmp/$ip_ftp/upload/ && sudo chmod 744 setup-full-$version-x86_64.run && sudo ./setup-full-$version-x86_64.run --mode unattended --enable-components server,ws
      else  
        echo -e "$Green \n 1c already installed $Color_Off" && sleep 1
      fi
      done
    fi ;; 
    2)
    echo -e "$Red \n aborted $Color_Off"
    sleep 1 ;;
    *)
    echo -e "$Red \n error $Color_Off"
    sleep 1
  esac

# Install mod_ssl
echo -e "$Cyan \n mod_ssl install $Color_Off"
if ! sudo rpm -qa | grep mod_ssl > /dev/null ; then
  yum -y install mod_ssl
else
  echo -e "$Green \n mod_ssl already installed $Color_Off" && sleep 1
fi

# Install openssh
echo -e "$Cyan \n openssh install $Color_Off"
if ! sudo rpm -qa | grep openssh > /dev/null ; then
  yum -y install openssh
else
  echo -e "$Green \n openssh already installed $Color_Off" && sleep 1
fi

# Configure httpd.conf
echo -e "$Cyan \n Configure httpd.conf $Color_Off" && sleep 1

if ! grep -q 'ServerName' /etc/httpd/conf/httpd.conf; then
  echo "ServerName $ServerName" | sudo tee -a /etc/httpd/conf/httpd.conf >/dev/null
else
  sudo sed -i "/ServerName/c\ServerName $ServerName" /etc/httpd/conf/httpd.conf
fi

if ! grep -q 'LoadModule _1cws_module "/opt/1cv8/x86_64/8\.3\..*\/wsap24.so"' /etc/httpd/conf/httpd.conf; then
 echo "LoadModule _1cws_module \"/opt/1cv8/x86_64/$version/wsap24.so\"" | sudo tee -a /etc/httpd/conf/httpd.conf >>/dev/null
else
 sudo sed -i "s|LoadModule _1cws_module \"/opt/1cv8/x86_64/8\.3\..*\/wsap24.so\"|LoadModule _1cws_module \"/opt/1cv8/x86_64/$version/wsap24.so\"|g" /etc/httpd/conf/httpd.conf
fi


# Install SSL
echo -e "$Cyan \n Configure SSL ? $Color_Off"
echo "1 - yes, 2 - no"
  read inst
  case $inst in
  1)
  rm -rf /etc/httpd/conf.d/ssl.conf $SertDir/$SSLCF $SertDir/$SSLCAF $SertKeyDir/$SSLKF >/dev/null
  files=(/tmp/$ip_ftp/upload/ssl.conf /tmp/$ip_ftp/upload/$SSLCAF /tmp/$ip_ftp/upload/$SSLCF /tmp/$ip_ftp/upload/$SSLKF)
  for file in "${files[@]}"; do
    if [[ ! -e $file ]]; then
      retries=0
      max_retries=3
      while [ $retries -lt $max_retries ]
      do 
          echo -e "$Yellow \n For download necessary files from FTP ($ip_ftp) please enter credentials! $Color_Off" && sleep 2
          echo -e "$Yellow \n Enter FTP user: $Color_Off"
          read -p user": " ftpuser
          echo -e "$Yellow \n Enter password for $ftpuser: $Color_Off"
          read -p password": " -s pass
          if wget --timeout=3 --tries=2 ftp://$ftpuser:$pass@$ip_ftp ; then
             rm -rf /tmp/10.* $CUR_DIR/index.*
             echo -e "$Green \n success connection, begin downloading...$Color_Off" && 
             wget --progress=dot -m -P /tmp ftp://$ftpuser:$pass@$ip_ftp:/upload/ssl.conf 2>&1 | awk 'NF>2 && $(NF-2) ~ /%/{printf "\r %s",$(NF-2)} END{print "\r   "}' &&
             wget --progress=dot -m -P /tmp ftp://$ftpuser:$pass@$ip_ftp:/upload/$SSLCF 2>&1 | awk 'NF>2 && $(NF-2) ~ /%/{printf "\r %s",$(NF-2)} END{print "\r   "}' &&
             wget --progress=dot -m -P /tmp ftp://$ftpuser:$pass@$ip_ftp:/upload/$SSLCAF 2>&1 | awk 'NF>2 && $(NF-2) ~ /%/{printf "\r %s",$(NF-2)} END{print "\r   "}' &&
             wget --progress=dot -m -P /tmp ftp://$ftpuser:$pass@$ip_ftp:/upload/$SSLKF 2>&1 | awk 'NF>2 && $(NF-2) ~ /%/{printf "\r %s",$(NF-2)} END{print "\r   "}' ;
             rm -rf $CUR_DIR/index.*
             break
          else
              calc=$((max_retries-1 - retries)) && echo -e "$Red \n wrong credentials, you have $calc attempts left $Color_Off" && retries=$((retries+1))
          fi
      done
      cp /tmp/$ip_ftp/upload/ssl.conf /etc/httpd/conf.d/
      cp /tmp/$ip_ftp/upload/$SSLCF $SSLCertificateFile
      cp /tmp/$ip_ftp/upload/$SSLKF $SSLCertificateKeyFile
      cp /tmp/$ip_ftp/upload/$SSLCAF $SSLCACertificateFile
      if ! grep -q 'SSLCertificateFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCertificateFile $SSLCertificateFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCertificateFile/c\SSLCertificateFile $SSLCertificateFile" /etc/httpd/conf.d/ssl.conf
      fi

      if ! grep -q 'SSLCertificateKeyFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCertificateFile $SSLCertificateKeyFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCertificateKeyFile/c\SSLCertificateKeyFile $SSLCertificateKeyFile" /etc/httpd/conf.d/ssl.conf
      fi

      if ! grep -q 'SSLCACertificateFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCACertificateFile $SSLCACertificateFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCACertificateFile/c\SSLCACertificateFile $SSLCACertificateFile" /etc/httpd/conf.d/ssl.conf
      fi
    else
      cp /tmp/$ip_ftp/upload/ssl.conf /etc/httpd/conf.d/
      cp /tmp/$ip_ftp/upload/$SSLCF $SSLCertificateFile
      cp /tmp/$ip_ftp/upload/$SSLKF $SSLCertificateKeyFile
      cp /tmp/$ip_ftp/upload/$SSLCAF $SSLCACertificateFile
      if ! grep -q 'SSLCertificateFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCertificateFile $SSLCertificateFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCertificateFile/c\SSLCertificateFile $SSLCertificateFile" /etc/httpd/conf.d/ssl.conf
      fi

      if ! grep -q 'SSLCertificateKeyFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCertificateFile $SSLCertificateKeyFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCertificateKeyFile/c\SSLCertificateKeyFile $SSLCertificateKeyFile" /etc/httpd/conf.d/ssl.conf
      fi

      if ! grep -q 'SSLCACertificateFile' /etc/httpd/conf.d/ssl.conf; then
        echo "SSLCACertificateFile $SSLCACertificateFile" | sudo tee -a /etc/httpd/conf.d/ssl.conf >/dev/null
      else
        sudo sed -i "/SSLCACertificateFile/c\SSLCACertificateFile $SSLCACertificateFile" /etc/httpd/conf.d/ssl.conf
      fi
    fi
  done
  echo -e "$Green \n Complete! $Color_Off"
  sleep 1 ;;
  2)
  echo -e "$Red \n aborted $Color_Off"
  sleep 1 ;;
  *)
  echo -e "$Red \n error $Color_Off"
  sleep 1
  esac

# Restart apache
echo -e "$Cyan \n Restart apache $Color_Off" && sleep 1
systemctl restart httpd && systemctl status httpd

# Add crontab task?
echo -e "$Cyan \n Add crontab task for checking certificate expiration? WARNING! THIS WILL DELETE ALL CURRENT CRON TASKS!!! $Color_Off"
echo "1 - yes, 2 - no"
  read cron_inst
  case $cron_inst in
  1)
  chmod 755 $CUR_DIR/check.sh
  ESCAPED_CUR_DIR=${CUR_DIR////\\/}
  sed -i "s/\.\/.env/$ESCAPED_CUR_DIR\/.env/g" $CUR_DIR/check.sh
  echo "*/1 * * * * $CUR_DIR/check.sh > $CUR_DIR/logs+errors 2>&1" | crontab -
  crontab -l
  echo -e "$Green \n Installed! $Color_Off" ;;
  2)
  echo -e "$Red \n aborted $Color_Off"
  sleep 1 ;;
  *)
  echo -e "$Red \n error $Color_Off"
  sleep 1
  esac


