#!/bin/bash

# Default port exposed from container is 8200
# Default license is collected from the license file ../vault_license.hlic

export VAULT_ADDR=http://localhost:8200
VAULT_LICENSE=$(cat ../vault_license.hlic)

export $VAULT_TOKEN=$(echo "my_temporary_token" |base64 )
echo $VAULT_TOKEN

docker run \
	--cap-add=IPC_LOCK \
	-e VAULT_DEV_LISTEN_ADDRESS='0.0.0.0:8200' \
	-e VAULT_ADDR='http://0.0.0.0:8200' \
	-e VAULT_DEV_ROOT_TOKEN_ID=$(echo $VAULT_TOKEN) \
	-e VAULT_LICENSE=$(echo $VAULT_LICENSE) \
	-p 8200:8200 \
	--name vault-1 \
	--detach \
	hashicorp/vault-enterprise

echo "The docker container to work on is:"
docker exec -ti $(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1) /bin/sh

echo "Logs from the container:"
docker logs $(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1)
