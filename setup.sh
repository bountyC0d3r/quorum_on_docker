#!/bin/bash

RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
BLUE=$'\e[1;34m'
END=$'\e[0m'
N=1
NETWORK_IP=10.50.0.
COMMA=","

function cleanup(){
    rm -rf $projectName
    mkdir $projectName
    echo $BLUE"Project Dir Created"$END
}

function createNodeDirs(){
    n=$N
    while [ "$n" -le "$nodeCount" ]; do
        mkdir -p $projectName/"node$n/dd/"{keystore,geth}
        echo $BLUE"Node:$n Dir Created"$END
        n=`expr "$n" + 1`;
    done
}

function createNodekeys(){
    n=$N
    while [ "$n" -le "$nodeCount" ]; do
        /usr/local/bin/bootnode -genkey $projectName/"node$n"/dd/geth/nodekey -writeaddress
        nodehex=$(/usr/local/bin/bootnode -nodekey $projectName/"node$n"/dd/geth/nodekey --writeaddress)

        if [ $n -eq $nodeCount ]; then
            COMMA=""
        fi
        
        # Generrate `static-nodes.json` file
        echo \"enode://$nodehex@$NETWORK_IP`expr "$n" + 1`:22001?discport=0\&raftport=22003\"$COMMA >> $projectName/static-nodes.json

        echo $BLUE"nodekey for Node:$n Created"$END
        n=`expr "$n" + 1`;
    done

    echo "]" >> $projectName/static-nodes.json
    echo $BLUE"static-nodes.json Created"$END
}

function createGethAccounts(){
    n=$N
    while [ "$n" -le "$nodeCount" ]; do
        # Password file for geth command line
        touch $projectName/"node$n"/password.txt
        COMMA=",";

        if [ $n -eq $nodeCount ]; then
            COMMA=""
        fi

        address=$(/usr/local/bin/geth --datadir=$projectName/node$n/dd --password $projectName/node$n/password.txt account new | cut -c 11-50)
        echo "\"$address\": {\"balance\": \"1000000000000000000000000000\"}$COMMA">> $projectName/gethAccounts.txt
        n=`expr "$n" + 1`;
    done
    echo $BLUE"Geth Accounts Created"$END
}

function createConstellationKeys(){
    n=$N
    while [ "$n" -le "$nodeCount" ]; do
        #Generate constellation keys
        echo -ne "\n" | /usr/local/bin/constellation-node --workdir=$projectName/node$n/keys --generatekeys=tm 1>>/dev/null
        echo -ne "\n" | /usr/local/bin/constellation-node --workdir=$projectName/node$n/keys --generatekeys=tma 1>>/dev/null

        n=`expr "$n" + 1`;
    done
    echo $BLUE"Constellation Keys Created"$END
}

function createConfigFiles(){
    n=$N

    cp genesis_template.json $projectName/genesis.json
    sed -i "s/#accountdetails#/`cat $projectName/gethAccounts.txt | tr -d '[:space:]' | tr -d '\n'`/g" $projectName/genesis.json

    while [ "$n" -le "$nodeCount" ]; do
        IP=$NETWORK_IP`expr "$n" + 1`;
        # Generate `tm.conf` file
        cp tm_template.conf $projectName/node$n/tm.conf;
        sed -i "s/#ipaddress#/$IP/g" $projectName/node$n/tm.conf

        # Generate `start-node.sh` file
        cp start-node_template.txt $projectName/node$n/start-node.sh;
        sed -i "s/#ipaddress#/$IP/g" $projectName/node$n/start-node.sh
        chmod +x $projectName/node$n/start-node.sh

        # Copy genesis.json file to nodes
        cp $projectName/genesis.json $projectName/node$n/genesis.json

        # Copy static-nodes.json file to nodes
        cp $projectName/static-nodes.json $projectName/node$n/dd/static-nodes.json

        n=`expr "$n" + 1`;
    done

    rm -rf $projectName/static-nodes.json $projectName/genesis.json $projectName/gethAccounts.txt

    echo $BLUE"Other Required Files Created"$END
}

function createDockerComposeFile(){
    echo "version: '2'" > $projectName/docker-compose.yml
    echo "networks:" >> $projectName/docker-compose.yml
    echo "  nodenet:" >> $projectName/docker-compose.yml
    echo "    driver: bridge" >> $projectName/docker-compose.yml
    echo "    ipam:" >> $projectName/docker-compose.yml
    echo "      config:" >> $projectName/docker-compose.yml
    echo "        - subnet: "$NETWORK_IP"0/16" >> $projectName/docker-compose.yml
    echo "          gateway: "$NETWORK_IP"1" >> $projectName/docker-compose.yml
    echo "" >> $projectName/docker-compose.yml
    echo "services:" >> $projectName/docker-compose.yml

    n=$N;
    while [ "$n" -le "$nodeCount" ]; do
        echo "  node"$n":" >> $projectName/docker-compose.yml
        echo "    image: dushyantbhalgami/quorum" >> $projectName/docker-compose.yml
        echo "    volumes:" >> $projectName/docker-compose.yml
        echo "      - ./node$n:/node" >> $projectName/docker-compose.yml
        echo "    networks:" >> $projectName/docker-compose.yml
        echo "      nodenet:" >> $projectName/docker-compose.yml
        echo "        ipv4_address: '"$NETWORK_IP`expr "$n" + 1`"'" >> $projectName/docker-compose.yml
        echo "    command: \"sh /node/start-node.sh\"" >> $projectName/docker-compose.yml

        n=`expr "$n" + 1`;
    done
}

function main(){
    DEFAULT_PROJECT_NAME="Development_Network"
    read -p $RED"Project Name [$DEFAULT_PROJECT_NAME]: "$END  projectName
    projectName="${projectName:-$DEFAULT_PROJECT_NAME}"
    echo $projectName

    DEFAULT_NODE_COUNT=3
    read -p $GREEN"Node Count [$DEFAULT_NODE_COUNT]: "$END  nodeCount
    nodeCount="${nodeCount:-$DEFAULT_NODE_COUNT}"
    echo $nodeCount

    cleanup
    echo "[" > $projectName/static-nodes.json
    createNodeDirs
    createNodekeys
    createGethAccounts
    createConstellationKeys
    createConfigFiles
    createDockerComposeFile

    printf $GREEN"You are all set to start the network. Execute following commands:"$END
    printf $BLUE"\n  1. cd $projectName\n  2. docker-compose up -d"$END
}

main $@