### ON Server 2

cd ~/fabric-samples/hlfnet
source .env
echo "Checking the  CLI name"   
echo $CLI_NAME
echo "Creating Channel"
docker exec "$CLI_NAME" peer channel create -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$CHANNEL_TX_LOCATION" --tls --cafile $ORDERER_CA
sleep 1
echo "Org1 Joining the channel.."
docker exec "$CLI_NAME" peer channel join -b "$CHANNEL_NAME".block --tls --cafile $ORDERER_CA
sleep 1
echo "Org2 Joining the channel.."
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org2.example.com/tls/server.crt" -e "CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" "$CLI_NAME" peer channel join -b "$CHANNEL_NAME".block --tls --cafile $ORDERER_CA
sleep 1 
echo "Org1 Installing the Fabcar chaincode..."
docker exec "$CLI_NAME" peer chaincode install -n "$CC_NAME" -p "$CC_SRC" -v "$CC_VERSION" -l "$CC_RUNTIME_LANGUAGE"
sleep 2
echo "Updating Anchor Peer for org1..."
docker exec "$CLI_NAME" peer channel update  -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$ORG1_ANCHOR_TX" --tls --cafile $ORDERER_CA
echo "Updating Anchor Peer for org2.."
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org2.example.com/tls/server.crt" -e "CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" "$CLI_NAME" peer channel update  -o "$ORDERER_NAME":7050 -c "$CHANNEL_NAME" -f "$ORG2_ANCHOR_TX" --tls --cafile $ORDERER_CA

echo "Org2 - Installing the Fabcar chaincode..."
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt "$CLI_NAME" peer chaincode install -n "$CC_NAME" -v "$CC_VERSION" -p "$CC_SRC" -l "$CC_RUNTIME_LANGUAGE"
sleep 5
echo "Instantiating the Fabcar chaincode..."
docker exec   -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} "$CLI_NAME"   peer chaincode instantiate  -o orderer.example.com:7050 -C mychannel -n "$CC_NAME" -l "$CC_RUNTIME_LANGUAGE" -v "$CC_VERSION" -c '{"Args":[]}' -P "AND('Org1MSP.member','Org2MSP.member')" --tls --cafile ${ORDERER_TLS_ROOTCERT_FILE} --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE}
sleep 15
echo "Querying the Fabcar Chaincode.."
echo "It will take some time..... "
docker exec   -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_MSPCONFIGPATH=${ORG1_MSPCONFIGPATH} "$CLI_NAME"   peer chaincode invoke -o orderer.example.com:7050  -C mychannel -n fabcar -c '{"function":"initLedger","Args":[]}' --waitForEvent --tls  --cafile ${ORDERER_TLS_ROOTCERT_FILE}  --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles ${ORG1_TLS_ROOTCERT_FILE} --tlsRootCertFiles ${ORG2_TLS_ROOTCERT_FILE}
