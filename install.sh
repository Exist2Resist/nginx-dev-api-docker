#!/bin/bash
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TZ /etc/localtime

yum install -y epel-release 
yum update -y 
yum install -y yum-utils gcc python-pip python-devel wget nginx tmux curl unzip
yum -y groupinstall development
pip install --upgrade pip
pip install vitualenv

##Install Python 3.x dev env tools
yum -y install https://centos7.iuscommunity.org/ius-release.rpm
yum -y install python36u
yum -y install python36u-pip
yum -y install python36u-devel

##Make env folder
mkdir /nginx /environments

##Change folder ownership and permission.
chown -R nobody:users /nginx /environments
chmod -R 755 /nginx /environments

##Append the nginx service file, copy new configuration file. 
##Shouldn't be changing the /usr/lib/systemd file, should be working in dopr in file /etc/systemd/system 
##but the systemd python replacement script does not support 'systemctl edit nginx.service' drop in files.
FILE="/usr/lib/systemd/system/nginx.service"
DEST="/etc/systemd/system/nginx.service"

LINE=$(cat /usr/lib/systemd/system/nginx.service | grep -n "ExecStart=" | cut -d: -f1)
APPEND=$(cat /usr/lib/systemd/system/nginx.service | grep "ExecStart=")
CONFIG=" -c /nginx/nginx.conf"

awk -v "LINE=$LINE" -v "APPEND=$APPEND" -v "CONFIG=$CONFIG" \
'NR==LINE{gsub(APPEND, APPEND""CONFIG)};1' \
$FILE > $FILE"tmp" && mv -f $FILE"tmp" $DEST

#Add ExecPreStartup=/usr/local/bin/start.sh to line 11 of the nginx unit file
sed -i '11 i ExecStartPre=/usr/local/bin/start.sh' /etc/systemd/system/nginx.service

#LINE_U=$(cat $FILE | grep -n "After=" | cut -d: -f1)
#APPEND_U=$(cat $FILE | grep "After=")
#AFTER=" startup.service"

#awk -v "LINE_U=$LINE_U" -v "APPEND_U=$APPEND_U" -v "AFTER=$AFTER" \
'NR==LINE_U{gsub(APPEND_U, APPEND_U""AFTER)};1' \
$DEST > $DEST"tmp" && mv -f $DEST"tmp" $DEST 

#sed -i '1s/^/[Unit]\nDescription=Custom Nginx Service Unit.\nAfter=startup.service\n\n/' /etc/systemd/system/nginx.service 

##Install ODBC driver for RedHat7
curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo
yum remove -y unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
ACCEPT_EULA=Y yum install -y msodbcsql17
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
yum install -y unixODBC-devel

## Startup Script
cat <<'EOF' > /usr/local/bin/start.sh
#!/bin/bash
#Sets the timezone in the container and sets up dev environment. 

TIMEZONE=${TZ:-America/Edmonton}
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

#Set UID and GID and change folder permission
USERID=${PUID:-99}
GROUPID=${GUID:-100}

groupmod -g $GROUPID users
usermod -u $USERID nobody
usermod -g $USERID nobody
usermod -d /home nobody

chown -R nobody:users /nginx /environments
chmod -R 755 /nginx /environments

#Check if nginx config file exists if not copy it
if [[ ! -f /nginx/nginx.conf ]];then
	echo "Creating Nginx configuration file in volume"
	cp /etc/nginx/nginx.conf /nginx
fi

#Create new pythong dev env
cd /environments
python3.6 -m venv $DEV_ENV

#Activate environment
source $DEV_ENV/bin/activate

EOF

chmod 755 /usr/local/bin/start.sh

##Create Startup service for the above script
cat <<'EOF' > /etc/systemd/system/startup.service
[Unit]
Description=Startup Script, sets TZ, user/group, config location, and dev environment.
Before=nginx.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

yum clean all

#systemctl enable startup.service
#service fails added ExecPreStartup to nginx.servce
systemctl enable nginx.service