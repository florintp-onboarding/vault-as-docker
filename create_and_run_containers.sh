#!/bin/bash
# Default port exposed from container is $VAULT_PORT or the ARGV
# Syntax is:
#           ./create_and_run_containers.sh <PORT_VAULT1> [<VAULT_PORT2>] [<VAULT_PORT2>] [<VAULT_PORTN>]
# where VAULT_PORT[1-n] are in the format 8[0-9][0-9][0-9]


# Default license is collected from the license file ../vault_license.hlic
# The demo will be kept alive for a number of seconds as per variable TIMEDEMO
# Default value for TIMEDEMO is 3600 seconds. TIMEDEMO=3600
export TIMEDEMO=3600

# DEBUG information is printed if there is a terminal and if the value is greater than ZERO.
export DEBUG=0

export VAULT_LICENSE=$(cat ../vault_license.hlic)
[ -t ] && [ $DEBUG -gt 0 ] && echo -ne "\nLicense used:$VAULT_LICENSE\n"


function create_container()
{
  local VAULT_PORT=$1
  local _errmsg=0
  [ -t ] && echo -ne "\n### Creating vault container vault-$VAULT_PORT\n"
  local VAULT_ADDR=http://localhost:$VAULT_PORT
  local VAULT_TOKEN=$(echo "my_temporary_token_$VAULT_PORT" |base64 )
  [ -t ] && echo -ne "### Token used: $VAULT_TOKEN\n"
  
  [ -t ] && [ $DEBUG -gt 0 ] && echo -ne "\n### Executing the docker command for  vault-$VAULT_PORT\ndocker run \ 
--cap-add=IPC_LOCK \ 
-e VAULT_DEV_LISTEN_ADDRESS=\"0.0.0.0:$VAULT_PORT\" \\
-e VAULT_ADDR=\"http://0.0.0.0:$VAULT_PORT\" \\
-e VAULT_API_ADDR=\"http://0.0.0.0:$VAULT_PORT\" \\
-e VAULT_DEV_ROOT_TOKEN_ID=\$(echo \$VAULT_TOKEN) \\
-e VAULT_LICENSE=\$(echo \$VAULT_LICENSE) \\
-p $(echo $VAULT_PORT):8200 \\
--name vault-$(echo $VAULT_PORT) \\
--detach \\
hashicorp/vault-enterprise \n"

  INIT_RESPONSE=$(docker run --cap-add=IPC_LOCK -e VAULT_DEV_LISTEN_ADDRESS="0.0.0.0:$VAULT_PORT" -e VAULT_ADDR="http://0.0.0.0:$VAULT_PORT" -e VAULT_API_ADDR="http://0.0.0.0:$VAULT_PORT" -e VAULT_DEV_ROOT_TOKEN_ID=$(echo $VAULT_TOKEN) -e VAULT_LICENSE=$(echo $VAULT_LICENSE) -p $(echo $VAULT_PORT):8200 --name vault-$(echo $VAULT_PORT) --detach  hashicorp/vault-enterprise )
  _errmsg=$?
  [ -t ] && [ $DEBUG -gt 0 ] && echo "### Status: ${_errmsg} : docker_id=$INIT_RESPONSE" 
 return ${_errmsg}
}


# MAIN BLOCK
# Parse the arguments received from calling the script
export containers=""
export arguments=$#
while [[ "$#" -gt 0 ]]; do
    case $1 in
        8[0-9][0-9][0-9])
	   create_container $1 && containers="$containers vault-$1"
	   #[ $? -eq 0 ] && containers="$containers vault-$1"
	   ;;
        *) echo -ne "\n# Invalid port for vault passed: $1 "
	   echo "Skipping this argument."
	   ;; 
    esac
    shift
done
echo $containers

# If no valid ports were provided, that a default 8200 is started.
[ "X$containers" == "X" ] && [ $arguments -eq 0 ] && create_container 8200 && export containers="vault-8200"


[ "X$containers" == "X" ] || (echo "Sleeping $TIMEDEMO seconds" ; sleep $TIMEDEMO )

if [ "X$containers" == "X" ] ; then
  :
else
#echo "Sleeping $TIMEDEMO seconds" ; sleep $TIMEDEMO
:
fi

for container in $(docker ps -q -a -f  "ancestor=hashicorp/vault-enterprise"  --format "{{.Names}}") ; do
   # If the container is in our list of started containers we will remove it otherwise it will print out the manual cleanup.
   if [ $(echo $containers|grep $container|wc -l) -ge 1 ]  ; then
      [ -t ] && echo -ne "\n### Removing container $container "
      docker rm $container --force 1>/dev/null 
      [ $? -eq 0 ] && [ -t ] && echo -ne "OK" || echo -ne "Failed." 
   else
       [ -t ] && echo -ne "\n### Manual retry\ndocker rm $container --force"
   fi
done

echo
