#!/bin/bash
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TZ /etc/localtime

yum install -y epel-release 
yum update -y 
yum install -y nginx wget tmux curl unzip python-pip python-devel gcc
pip install vitualenv
yum -y install python36u
yum -y install python36u-pip

yum clean all

chown -R nobody:usrs /etc/nginx

## Startup Script
cat <<'EOF' > /usr/local/bin/start.sh
#!/bin/bash
#Sets the timezone in the container. 

TIMEZONE=${TZ:-America/Edmonton}
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

/etc/nginx

EOF

##Create Startup service for the above script
cat <<'EOT' > /etc/systemd/system/startup.service
[Unit]
Description=Startup Script.
Before=mginx.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOT

systemctl enable startup.service
systemctl enable nginx.service