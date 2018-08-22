# Quorum_On_Docker
Using the script generate the required artifacts to start the Quorum network with desired number of nodes.

This script will launch the Quorum network using docker containers.

This script will generate the network using Quorum **v2.0.2**

## Prerequisite
- **Constellation (v0.3.2)**
  ```
  wget -q https://github.com/jpmorganchase/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz
  tar xfJ constellation-0.3.2-ubuntu1604.tar.xz
  cp constellation-0.3.2-ubuntu1604/constellation-node /usr/local/bin && chmod 0755 /usr/local/bin/constellation-node
  ```
- **[Go Lang](https://golang.org/doc/install)**
- **Quorum**
```
git clone https://github.com/jpmorganchase/quorum.git
cd quorum
git checkout tags/v2.0.2
make all
cp build/bin/geth /usr/local/bin
cp build/bin/bootnode /usr/local/bin
```
- **Porosity**
```
wget -q https://github.com/jpmorganchase/quorum/releases/download/v1.2.0/porosity
mv porosity /usr/local/bin && chmod 0755 /usr/local/bin/porosity
```

## How to use:
```
./setup.sh
> Project Name [Development_Network]: {PROVIDE PROJECT NAME, Default - Development_Network}
> Node Count [3]: {PROVIDE NODE COUNT, Default - 3}
>
  Project Dir Created
  Node:1 Dir Created
  Node:2 Dir Created
  Node:3 Dir Created
  nodekey for Node:1 Created
  nodekey for Node:2 Created
  nodekey for Node:3 Created
  static-nodes.json Created
  WARN [08-22|20:58:35] No etherbase set and no accounts found as default 
  WARN [08-22|20:58:36] No etherbase set and no accounts found as default 
  WARN [08-22|20:58:37] No etherbase set and no accounts found as default 
  Geth Accounts Created
  Constellation Keys Created
  Other Required Files Created
  You are all set to start the network. Execute following commands:
    1. cd Development_Network
    2. docker-compose up -d
```