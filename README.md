[![license](http://img.shields.io/badge/license-apache_2.0-red.svg?style=flat)](https://github.com/florintp-onboarding/vault-as-docker/blob/main/LICENSE)

# Running Vault Enterprise as a Docker container(s)

## Create a container from the latest hashicorp/vault-enterprise image
The current repository is used for initial setup and configure of a Vault server running as container on a local Docker system.
The Vault server image is created as per latest HashiCorp enterprise image available at ```hashicorp/vault-enterprise```.
Prior to start and run the image, a valid Vault license is required. The login ROOT_TOKEN should be also initialized at image creation.

For exercise purposes, the following points apply:
- license should be available and readable as (```../vault_license.hclic```)
- the ROOT_TOKEN will be generated at image creation (a simple text converted via base64)
- the Vault server will be started in DEV mode (initialised and unsealed)

**Please note**: (Optional) Run all in one script ```create_and_run_container.sh```

## Prerequisites:
* Install and configure [Docker](https://docker.com)
* Minimal Vault exposure [Vault-Getting-started](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install?in=vault%2Fgetting-started)



## Steps for achieving the goal (one manual container)
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
        --network vault-prometheus \
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

6. Stop the container and cleanup the image
```shell
docker rm --force $(docker ps -q -f  "ancestor=hashicorp/vault-enterprise" -f "status=running" --format "{{.Names}}"|head -n1)
```

## Steps for creating multiple docker containers running Vault
1. (Optional) Enable debug of script by updating the DEBUG variable with a numeric value greater than 0.
By default is disabled - DEBUG=0.

2. Configure the estimated time for test/work by including the number of seconds in the variable TIMEDEMO.
By default TIMEDEMO=3600.

3. Execute the script create_and_run_containers.sh with syntax:
create_and_run_container.sh [<vault_port1>] [<Vault_port2>] ....

- Example 1 (create a default 8200 Vault container listening port with the default TIMEDEMO):
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
bash create_and_run_container.sh
````

- Example 2 (create 2 containers listening on 8200 and 8204 with the default TIMEDEMO):
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
bash create_and_run_containers.sh 8200 8204
````

- Example 3 (create 2 containers listening on 8200 and 8204 with the default TIMEDEMO=10 seconds):
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
export TIMEDEMO=10
bash create_and_run_containers.sh 8200 8204
````

- Example 4 (create 2 containers listening on 8200 and 8204 and leave them running):
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
bash /create_and_run_containers.sh 8200 8204 -b
````

- Example 5 (create 2 containers listening on 8200 and 8204 with the default TIMEDEMO=10 seconds and enable DEBUG):
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
bash /create_and_run_containers.sh 8200 8204 -f
````

- Example 5 (CLEANUP all containers)
````
export VAULT_TAG='hashicorp/vault-enterprise:1.14.0-ent'
bash /create_and_run_containers.sh -c 
````

