# Hyperledger Fabric 1.4.3 on Multiple Hosts using Docker Swarm, Compose and Fabcar applications


  <b> Prerequisites </b>

For Learning  Hyperlerger fabric with multiple hosts using docker swarm.
To learn Hyplerledger fabric with default samples. forked from fabric-sample 1.4.3

Ensure all prerequesties are completed, if not refer this [Download_script](https://github.com/ravinayag/Hyperledger/blob/master/download_hlf.sh) 
and [prereq_script](https://github.com/ravinayag/Hyperledger/blob/master/prereqs_hlfv14.sh)

* 1, Phy/Virtual Machine : Running Ubuntu OS 16.4 LTS
* 2, [Pre_req_script](https://github.com/ravinayag/Hyperledger/raw/master/prereqs_hlfv14.sh) for ref. (Installs : Docker, Docker-composer,Npm, node, python, ca-certs and sudo access.)
* 3, [Download_script](https://github.com/ravinayag/Hyperledger/raw/master/download_hlf.sh) for ref. (Installs : Fabric-samples, fabcar, binaries, docker images )
     <br/> Note : The script pointing to 1.4.2, pls change to 1.4.3 
* 4, Populate your DNS or /etc/hosts file to reflect the names. (Optional) <br /> 
  <b> ex : <br /> </b>
     185.254.200.100 orderer.example.com server1 <br />
     orderer.example.com   >>>> is your docker service name, so other hosts can ping with this name <br />
     server1  >>>> real hostname (since the hostname is binded to local dns), its optional <br />
     
    <b> For other servers : <br /> </b>
    185.254.200.101 peer0.org1.example.com peer1.org1.example.com ca.org1.example.com ca_org1 couchdb0 couchdb1 cli server2 <br />
    185.253.200.102 peer0.org2.example.com peer1.org2.example.com couchdb3 ca.org2.example.com ca_Org2 couchdb2 server3 <br />
    
 * 5, This is optional , I used NFS for file transfer between hosts, You can copy files at your style to all servers <br />
   echo "/mnt/nfs_share  185.0.0.0/24(rw,sync,no_subtree_check)" >>  /etc/exports <br />
   exportfs -a  <br />
   share /mnt/nfsshare at server server side <br />
   @client side :
   sudo mount 185.254.200.100:/mnt/nfsshare /home/ravi/share
### Lets begin to to dirt hands

Create a folder "hlfnet" under ~/fabric-samples/ and move to this location
```
cd ~/fabric-samples/hlfnet
copy configtx.yml crypto-config.yml from firstnetwork
copy  org1, org2 , .env  folder and file that shared with you
```   
#### Now generate the artifacts 
```
rm -rf crypto-config channel-artifacts
source ./env
cryptogen generate --config=./crypto-config.yaml
```
#### Create Sys channel for genesis block
``` 
mkdir channel-artifacts
configtxgen -profile TwoOrgsOrdererGenesis -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block
```
#### create channel.tx file
```
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME 
```

#### create Anchor peer file for Org
```
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ORG1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP 
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ORG2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
```

#### Docker Swarm Setup
```
docker swarm init
you  will get like this  >>> 
docker swarm join --token SWMTKN-1-1o6t607bt7iborcl8oc0l2ofwsp5byt9jqt3vbd1b3maee2pur-ewj0ie4vkgmnixnwh571h82w0 185.254.206.37:2377
note : dont copy above, its only for ref.
>> now join the other 2 nodes with above command   and promote 
docker node promote server2 
docker node promote server3 

docker node ls
```
Note: Copy CA Key file to org1/docker-compose-service.yml and org2/docker-compose-service.yml
key files can be locate like this.
```
@pc2:~/fabric-samples/hlfnet$ ls -l crypto-config/peerOrganizations/org1.example.com/ca/
total 8
-rwxr-xr-x 1 ravi ravi 241 Jun 14 23:45 3bf1c0216e3a5fd39c5ffdd3e60c2e4d592d046857818648b0d3b7a21b7d53cb_sk

```
copy the file name and replace at line # 31 and 34 exactly with  file name ends with _sk 


#### Create a network by below cmd
```
docker network create --attachable --driver overlay fabcar_net   
```



#### At this stage ensure all the folders, files are copied in all hosts, if not do it so.

### Deploy the hlf service
```
docker stack deploy -c "$ORDERER_COMPOSE_PATH" hlf_orderer

docker stack deploy -c "$SERVICE_ORG1_COMPOSE_PATH" hlf_services
docker stack deploy -c "$PEER_ORG1_COMPOSE_PATH" hlf_peer

docker stack deploy -c "$SERVICE_ORG2_COMPOSE_PATH" hlf_services
docker stack deploy -c "$PEER_ORG2_COMPOSE_PATH" hlf_peer
```
#### You can check on other nodes by docker stack or service
```
docker stack ls 
docker service ls
```
Once all the network  containers are up, then go for channel creation and join the channels

#### Channel Creation 
```
docker exec "$CLI_NAME" peer channel create -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$CHANNEL_TX_LOCATION" --tls --cafile $ORDERER_CA

#### Join peer0.org1 to channel
docker exec "$CLI_NAME" peer channel join -b "$CHANNEL_NAME".block --tls --cafile $ORDERER_CA

#### Join peer0.org2 to channel
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" \
  -e "CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org2.example.com/tls/server.crt" \
  -e "CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
  -e "CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
  -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" \
  "$CLI_NAME" peer channel join -b "$CHANNEL_NAME".block --tls --cafile $ORDERER_CA

#### Update Anchor peer, peer0.org1 to channel
docker exec "$CLI_NAME" peer channel update  -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$ORG1_ANCHOR_TX" --tls --cafile $ORDERER_CA
#### Update Anchor peer, peer0.org2 to channel
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" \
  -e "CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org2.example.com/tls/server.crt" \
  -e "CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
  -e "CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
  -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" \
  "$CLI_NAME" peer channel update  -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$ORG2_ANCHOR_TX" --tls --cafile $ORDERER_CA

#### Install fabcar chaincode on org1
docker exec "$CLI_NAME" peer chaincode install -n "$CC_NAME" -p "$CC_SRC" -v "$CC_VERSION" -l "$CC_RUNTIME_LANGUAGE"
#### Install fabcar chaincode on org2
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=${ORG2_MSPCONFIGPATH} \
  -e CORE_PEER_TLS_ROOTCERT_FILE=${ORG2_TLS_ROOTCERT_FILE} \
  "$CLI_NAME" peer chaincode install -n "$CC_NAME" -v "$CC_VERSION" -p "$CC_SRC" -l "$CC_RUNTIME_LANGUAGE"

#### Instantiating the Fabcar chaincode 
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  "$CLI_NAME" peer chaincode instantiate -o orderer.example.com:7050 \
  -C "$CHANNEL_NAME" -n "$CC_NAME" -l "$CC_RUNTIME_LANGUAGE" -v "$CC_VERSION" \
  -c '{"Args":[]}' -P "AND('Org1MSP.member','Org2MSP.member')" \
  --tls --cafile ${ORDERER_TLS_ROOTCERT_FILE} --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}

#### Query fabcar tx
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} \
  "$CLI_NAME" peer chaincode invoke -o orderer.example.com:7050 \
    -C mychannel -n fabcar -c '{"function":"initLedger","Args":[]}' \
    --waitForEvent --tls --cafile ${ORDERER_TLS_ROOTCERT_FILE} \
    --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 \
    --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE}
```    
#### Thats all the Fabric chaincode is install , instantiated across docker swarm nodes. 

### Now Lets get into fabcar application backend and frontend

Source  : https://blog.chhaileng.com/posts/hyperledger-fabric-fabcar-client-app/

#### Follow the procedure as per the guide lines 

### Appendix
Troubleshooting commands for docker swarm
docker service ps hlf_orderer_orderer_org1
docker stack ps hlf_orderer_orderer_org1

