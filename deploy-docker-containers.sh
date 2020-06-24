##### ON Server 1 only 
source .env
echo
echo "##### Remember, you have to update the crypto key files in  org1/docker-composer-services.yml & org2/docker-composer-services.yml "
echo "##### for CA services, else containers will fail, if not 'Ctrl+c' here  "
echo 
echo 
sleep 10



echo "Creating the network to join the docker nodes"
docker network create --attachable --driver overlay "$SWARM_NET"
echo
##### ON Server 1 or any but it should be in sequence
echo "starting the Orderer node..."
docker stack deploy -c "$ORDERER_COMPOSE_PATH" hlf_orderer
sleep 5
echo "starting the Org1 services..."
docker stack deploy -c "$SERVICE_ORG1_COMPOSE_PATH" hlf_services
sleep 5
echo "starting the Org1 peer nodes..."
docker stack deploy -c "$PEER_ORG1_COMPOSE_PATH" hlf_peer
sleep 3
echo "starting the Org2 services..."
docker stack deploy -c "$SERVICE_ORG2_COMPOSE_PATH" hlf_services
sleep 5
echo "starting the Org2 peer nodes..."
docker stack deploy -c "$PEER_ORG2_COMPOSE_PATH" hlf_peer
sleep 5

docker service ls
echo
echo 
echo "##### Login to  $ORG1_HOSTNAME  and start the channel creation script"
