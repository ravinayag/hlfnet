### ON Server 1
### Initiate the Docker Swarm and join the other hosts.
echo "Initiate the Docker Swarm and join the other hosts... "
source .env
docker swarm leave -f
docker swarm init
echo "Copy  and run this on other nodes.  Ex : 'docker swarm join {token...............}  ' "
sleep 10
docker node promote $ORG1_HOSTNAME
docker node promote $ORG2_HOSTNAME
docker node ls