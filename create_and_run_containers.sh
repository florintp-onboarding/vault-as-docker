#!/bin/bash
# Default port exposed from container is $VAULT_PORT or the ARGV
# Syntax is:
#           ./create_and_run_containers.sh <PORT_VAULT1> [<VAULT_PORT2>] [<VAULT_PORT2>] [<VAULT_PORTN>] [ [-b] | [-f] ]
# where VAULT_PORT[1-n] are in the format 8[0-9][0-9][0-9]
# [-b] - allow the creation of the containers and leave them running
# [-f] - force stop and remove all the containers


# Default license is collected from the license file ./vault_license.hclic
# The demo will be kept alive for a number of seconds as per variable TIMEDEMO
# Default value for TIMEDEMO is 3600 seconds. TIMEDEMO=3600
export TIMEDEMO=${TIMEDEMO:-36000}

# DEBUG information is printed if there is a terminal and if the value is greater than ZERO.
export DEBUG=${DEBUG:-0}

export VAULT_LICENSE=$(cat vault_license.hclic 2>/dev/null)
if [ "Z$VAULT_LICENSE" == "Z" ] ; then
	printf '\nNo valid license loaded!\n'
	exit 1
fi

[ -t ] && [ $DEBUG -gt 0 ] && echo -ne "\nLicense used:$VAULT_LICENSE\n"

# The Docker Vautl TAG variable may be completed in the environment like
# export VAULT_TAG='hashicorp/vault-enterprise:1.13.1-ent'
export VAULT_TAG=${VAULT_TAG:-hashicorp/vault-enterprise}
[ -t ] && [ $DEBUG -gt 0 ] && echo -ne "\nVault version used:$VAULT_TAG\n"

function container_present()
{
  [ $DEBUG -gt 0 ] && set -x
  local container=$1
  local found=0
  for lcontainer in $(docker ps -a  --format "{{.Names}}") ; do
   # If the container is already started will print out the manual cleanup.
   if [ "$container" == "$lcontainer" ]  ; then
     found=1 && break 1
   fi
   done
   set +x
   return $found
}

function create_container()
{
  [ $DEBUG -gt 0 ] && set -x
  local VAULT_PORT=$1
  local CLUSTER_VAULT_PORT=$(($VAULT_PORT + 1))
  local _errmsg=0
  container_present "vault-$VAULT_PORT" || return 1

  [ -t ] && printf  '\n### Creating vault container %s' "vault-$VAULT_PORT"
  local VAULT_ADDR=http://localhost:$VAULT_PORT

  docker network inspect vault-prometheus &>/dev/null || docker network create --driver bridge vault-prometheus &>/dev/null
  [ -t ] && [ $DEBUG -gt 0 ] && echo -ne "\n### Executing the docker command for  vault-$VAULT_PORT\ndocker run \
--cap-add=IPC_LOCK \
-e VAULT_API_ADDR=\"http://0.0.0.0:$VAULT_PORT\" \\
-e VAULT_LICENSE=\$(echo \$VAULT_LICENSE) \\
--name vault-$(echo $VAULT_PORT) \\
--network=vault-prometheus
-e VAULT_LOG_LEVEL="trace"
-e 'VAULT_LOCAL_CONFIG={"storage":{"raft":{"path":"/tmp/","node_id":"vault_$VAULT_PORT"}},"listener":{"tcp":{"address":"0.0.0.0:$VAULT_PORT","tls_disable":"true"}},"api_addr":"http://vault_1:$VAULT_PORT","cluster_addr":"http://vault_1:$CLUSTER_VAULT_PORT","telemetry":{"disable_hostname":true,"prometheus_retention_time":"12h"}}'
--detach \\
hashicorp/vault-enterprise \n"

  ### INIT_RESPONSE=$(docker run --detach --name vault-$(echo $VAULT_PORT) -p $VAULT_PORT:$VAULT_PORT -p $CLUSTER_VAULT_PORT:$CLUSTER_VAULT_PORT --cap-add=IPC_LOCK -e VAULT_LICENSE=$(echo $VAULT_LICENSE)  -e 'VAULT_LOCAL_CONFIG={"storage":{"raft":{"path":"/tmp/","node_id":"vault_'$VAULT_PORT'"}},"ui":"true","enable_response_header_hostname":"true","enable_response_header_raft_node_id":"true","listener":{"tcp":{"address":"0.0.0.0:'$VAULT_PORT'","tls_disable":"true"}},"api_addr":"http://0.0.0.0:'$VAULT_PORT'","cluster_addr":"http://127.0.0.1:'$CLUSTER_VAULT_PORT'"}' hashicorp/vault-enterprise:1.13.1-ent server -non-interactive )
  INIT_RESPONSE=$(docker run --detach --network=vault-prometheus --name vault-$(echo $VAULT_PORT) -p $VAULT_PORT:$VAULT_PORT -p $CLUSTER_VAULT_PORT:$CLUSTER_VAULT_PORT --cap-add=IPC_LOCK -e VAULT_LOG_LEVEL="trace" -e VAULT_LICENSE=$(echo $VAULT_LICENSE)  -e 'VAULT_LOCAL_CONFIG={"storage":{"raft":{"path":"/tmp/","node_id":"vault_'$VAULT_PORT'"}},"ui":"true","enable_response_header_hostname":"true","enable_response_header_raft_node_id":"true","listener":{"tcp":{"address":"0.0.0.0:'$VAULT_PORT'","tls_disable":"true"}},"api_addr":"http://0.0.0.0:'$VAULT_PORT'","cluster_addr":"http://127.0.0.1:'$CLUSTER_VAULT_PORT'","telemetry":{"disable_hostname":true,"prometheus_retention_time":"12h"}}' $VAULT_TAG server -non-interactive )
  _errmsg=$?
  [ -t ] && [ $DEBUG -gt 0 ] && printf '\n### Status: %s : docker_id=$s' "${_errmsg}" "$INIT_RESPONSE"
  set +x
  return "${_errmsg}"
}

# MAIN BLOCK
# Parse the arguments received from calling the script
export containers=""
export arguments=$#
while [[ "$#" -gt 0 ]]; do
    case $1 in
        8[0-9][0-9][0-9])
	   ( create_container $1 )
	   [ $? -eq 0 ] &&  containers="$containers vault-$1" || printf '\nFailed to create container: %s ' "vault-$1"
	   ;;
        '-f' )
	   export DEBUG=1
           printf "\n#Increasing DEBUG level"
	   set -x
	   ;;
        '-b' )
	   export TIMEDEMO=0
           printf '\n#Creating containers and leave them in background.'
	   ;;
        *) printf '\n#Invalid port for vault passed:%s\nSkipping this argument.' "$1"
	   ;; 
    esac
    shift
done
printf '\n#Containers created: %s' "$containers"

# If no valid ports were provided, that a default 8200 is started.
[ "X$containers" == "X" ] && [ $arguments -eq 0 ] && create_container 8200 && export containers="vault-8200"

# If we succeeded to start at least one container we wait for finishing the exercise
if [[ "X$containers" != "X" ]] && 
   [[ $TIMEDEMO -gt 0 ]] ; then
   {
    printf '\n#Sleeping %s seconds (Add any char and enter to break)' "$TIMEDEMO" 
    for i in $(seq $TIMEDEMO) ; do
       printf '\r%s %s' '.' $(date '+%H:%M:%S')
       x1="" ; read -t1 x1 ; x1=${x1:-Z}
       [ "${x1}"  != "Z" ] && break 1
     done
     for container in $(docker ps -a -f  "ancestor=$VAULT_TAG"  --format "{{.Names}}") ; do
        # If the container is in our list of started containers we will remove it otherwise it will print out the manual cleanup.
        if [ $(echo $containers|grep $container|wc -l) -ge 1 ]  ; then
    	   [ -t ] && printf  "\n### Removing container %s" "$(docker rm $container --force)"
        else
	   # If we are running with DEBUG then we just forcible remove the containers
	   # else if we are in a terminal we provide the removal commands.
	   [ $DEBUG -gt 0 ] && printf '\n### Removing container %s' "$(docker rm $container --force)" || printf '\n### Execute a manual removal of container %s \ndocker rm %s --force' "$container" "$container" 
        fi
     done
}
else
    [[ "X$containers" == "X" ]] && echo "No containers were started"
    :
fi
set +x
echo
