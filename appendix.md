It might help

when you see error messages like this:
-bash: '\r': command not found
: command not found

Try running the dos2unix command on the file in question.

sed -i 's/\r$//' filenames

Replace the host name on docker compose file
sed -i -e 's/$ORDERER_HOSTNAME/lab/' org1/docker-compose-orderer.yml

docker node ps
docker service logs 
docker stack ps  hlf_services
