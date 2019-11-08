#!/bin/bash

NAME=myservice
PORT=8000
VERSION_TAG="$(echo $VERSION | sed 's/\s$// ; s/\./_/g')" # make DNS compliant


cat << EOF > /tmp/$NAME.service
[Unit]
Description=$NAME
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/$NAME/run.py
WorkingDirectory=/opt/$NAME
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
sudo chown root:root /tmp/$NAME.service
sudo mv /tmp/$NAME.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable $NAME

sudo cat << EOF > /tmp/consul-$NAME.json
{
  "services": [
    {
      "id": "$NAME",
      "name": "$NAME",
      "port": $PORT,
      "tags": ["$VERSION_TAG"],
      "checks": [
        {
          "http": "http://127.0.0.1:$PORT/health",
          "interval": "30s",
          "timeout": "5s"
        }
      ]
    }
  ]
}
EOF

sudo chown root:root /tmp/consul-$NAME.service
sudo mv /tmp/consul-$NAME.json /etc/consul/conf.d/$NAME.json