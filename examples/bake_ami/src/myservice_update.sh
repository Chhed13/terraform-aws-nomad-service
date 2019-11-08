#!/bin/bash

NAME=myservice

cat << EOF > /opt/$NAME/health
{
  "service": "$NAME",
  "environment": "$ENVIRONMENT",
  "any_env_special_info": "$MYSERVICE_SPECIAL_INFO"
}
EOF

sudo systemctl restart $NAME
