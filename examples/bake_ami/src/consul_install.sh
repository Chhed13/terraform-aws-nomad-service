#!/bin/bash

sudo yum install -y unzip

NAME=consul
VERSION=1.4.4

cd /tmp
curl -O https://releases.hashicorp.com/$NAME/$VERSION/$NAME\_$VERSION\_linux_amd64.zip
unzip $NAME\_$VERSION\_linux_amd64.zip
sudo chmod +x $NAME
sudo mv $NAME /usr/bin/$NAME

cat << EOF > /tmp/$NAME.service
[Unit]
Description=$NAME
After=network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/bin/$NAME agent -config-file=/etc/$NAME/$NAME.json -config-dir=/etc/$NAME/conf.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
RestartSec=10
WorkingDirectory=/var/lib/$NAME

[Install]
WantedBy=multi-user.target
EOF

sudo chown root:root /tmp/$NAME.service
sudo mv /tmp/$NAME.service /etc/systemd/system/

sudo mkdir -p /etc/$NAME/conf.d
sudo mkdir -p /var/lib/$NAME

sudo systemctl daemon-reload
sudo systemctl enable $NAME