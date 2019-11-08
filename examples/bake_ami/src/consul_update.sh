#!/bin/bash

NAME=consul

cat << EOF > /tmp/$NAME.json
{
  "datacenter": "$CONSUL_DATACENTER",
  "data_dir": "/var/lib/consul",
  "domain": "$CONSUL_DOMAIN",
  "retry_join": [$CONSUL_JOIN],
  "disable_remote_exec": true
}
EOF

sudo chown root:root /tmp/$NAME.json
sudo chmod 644 /tmp/$NAME.json
sudo mv /tmp/$NAME.json /etc/consul/

sudo systemctl restart $NAME
