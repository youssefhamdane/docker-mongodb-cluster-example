openssl rand -base64 741 > mongo-keyfile
chmod 600 mongo-keyfile
chown 999:docker mongo-keyfile
docker-compose up -d
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
    RET=1
    until [ ${RET} -eq 0 ]; do
    docker exec -it mongo_primary mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.initiate()";
    RET=$?
    sleep 5
    done
    echo "mongo_primary initiated"
    docker exec -it mongo_primary mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.add({host : \"mongo1:27017\" })";
    echo "mongo1 added"
    docker exec -it mongo_primary mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.add({host : \"mongo2:27017\" })";
    echo "mongo2 added"
    docker exec -it mongo_primary mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.add({host : \"mongo3:27017\" })";
    echo "mongo3 added"
    
    docker exec -it mongo_config_server1 mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.initiate()";
    echo "mongo_config_server1 initiated"
    docker exec -it mongo_config_server1 mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "rs.add({host : \"mongo_config_server2:27017\" })";
    echo "mongo_config_server2 added"
    
    docker exec -it mongo_router mongo admin -u $USERNAME -p $PASSWORD --quiet --eval "sh.addShard(\"rs-data0/mongo_primary:27017\")";
    echo "mongo_router configurated"
    
fi
exit