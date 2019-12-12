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

#Make env folder
mkdir /evironements

#Change folder ownership and permission.
chown -R nobody:users /etc/nginx /environments
chmod -R 755 /etc/nginx /environments

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

chown -R nobody:users /etc/nginx /environments
chmod -R 755 /etc/nginx /environments

#Create new pythong dev env
cd /environments
python3.6 -m venv $DEV_ENV

#Activate environment
source $DEV_ENV/bin/activate

EOF


##Create Startup service for the above script
cat <<'EOT' > /etc/systemd/system/startup.service
[Unit]
Description=Startup Script, sets TZ, user/group, and dev environment.
Before=mginx.service

[Service]
Group=users
ExecStart=/usr/local/bin/start.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOT

yum clean all

systemctl enable startup.service
systemctl enable nginx.service