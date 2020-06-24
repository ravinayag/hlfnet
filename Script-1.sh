### ON Server 1
### Copy the docker config files
cd ~/fabric-samples
mkdir hlfnet
cd hlfnet
cp ../first-network/configtx.yaml .
cp ../first-network/crypto-config.yaml .
cp ../hlfnet.new/.env .
cp ../hlfnet.new/* .
cp -r ../hlfnet.new/org1 .
cp -r ../hlfnet.new/org2 .
ls -altr
cd ~/fabric-samples/hlfnet

