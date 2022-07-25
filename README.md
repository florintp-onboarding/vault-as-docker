# Running Vault Enterprise as a Docker container

## Create a container from the latest hashicorp/vault-enterprise image
The current repository is used for initial setup and configure of a Vault server running as container on a local Docker system.
The Vault server image is created as per latest HashiCorp enterprise image available at ```hashicorp/vault-enterprise```.
Priot to start and run the image, a valid Vault license is required. The login ROOT_TOKEN should be also initialized at image creation.

For exercise purposes, the following points apply:
- license will be stored one directory up (```../vault_license.hlic```)
- the ROOT_TOKEN will be generated at image creation (a simple text converted via base64)
- the Vault server will be started in DEV mode (initialised and unsealed)

**Please note**: (Optional) Run all in one script ```create_and_run_container.sh```

## Prerequisites:
* Install and configure [Docker](https://docker.com)
* Minimal Vault exposure [Vault-Getting-started](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install?in=vault%2Fgetting-started)



## Steps for achieving the goal
1. Using the official image from HashiCorp create the image and run a container

```shell
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
```

2. Identify the docker id
```shell
docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running"
```

3. Identify the docker name
```shell
docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"
```

4. Login to the container by executing a /bin/sh
```shell
docker exec -ti $(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1) /bin/sh
```

5. Getting the logs from the Vault running container (including the UNSEAL KEY and ROOT TOKEN)
```shell
docker logs $(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1)
```

