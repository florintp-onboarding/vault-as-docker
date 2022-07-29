#!/bin/bash

# Default port exposed from container is 8200
# Default license is collected from the license file ../vault_license.hlic

# The demo will be kept alive for a number of seconds as per variable TIMEDEMO
# Default value for TIMEDEMO is 100 seconds. TIMEDEMO=100
export TIMEDEMO=100

export VAULT_ADDR=http://localhost:8200
VAULT_LICENSE=$(cat ../vault_license.hlic)
echo -ne "\nLicense is:\$VAULT_LICENSE\n"

export VAULT_TOKEN=$(echo "my_temporary_token" |base64 )
echo "Token used: $VAULT_TOKEN"

docker run \
	--cap-add=IPC_LOCK \
	-e VAULT_DEV_LISTEN_ADDRESS='0.0.0.0:8200' \
	-e VAULT_ADDR='http://0.0.0.0:8200' \
	-e VAULT_API_ADDR='http://0.0.0.0:8200' \
	-e VAULT_DEV_ROOT_TOKEN_ID=$(echo $VAULT_TOKEN) \
	-e VAULT_LICENSE=$(echo $VAULT_LICENSE) \
	-p 8200:8200 \
	--name vault-1 \
	--detach \
	hashicorp/vault-enterprise

echo "The docker container to work on is:"
docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.ID}}\t{{.Names}}"|head -n1

echo "Logs from the container:"
running_container=$(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1)

# Tail with follow on the logs of the new container...
docker logs --follow $running_container &
export temp_pid=$!
sleep 1

echo "Sleeping $TIMEDEMO seconds"
sleep $TIMEDEMO

[ $temp_pid -gt 100 ] && kill -STOP $temp_pid
[ $temp_pid -gt 100 ] && [ $(ps -fe|grep -v grep |grep $temp_pid|wc -l|tail -n1 2>/dev/null) -ge 1 ] && kill -TERM  $temp_pid

docker rm --force $(docker ps -q -a -f  "ancestor=hashicorp/vault-enterprise"  --format "{{.Names}}"|head -n1)
