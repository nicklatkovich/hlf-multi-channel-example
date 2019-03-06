set -e

function __HEADER__ {
	echo -e "\033[0;31m # ${1}\033[0m ..."
}

__HEADER__ "CLEANUP"
mkdir -p ./crypto-config
rm -rf ./crypto-config/*
mkdir -p ./artifacts
rm -rf ./artifacts/*

__HEADER__ "KEYS GENERATION"
cryptogen generate --config=./crypto-config.yaml

__HEADER__ "GENESIS BLOCK GENERATION"
configtxgen -profile OrdererGenesis -outputBlock ./artifacts/genesis.block

__HEADER__ "CHANNELS GENERATION"
configtxgen -profile CommonChannel -outputCreateChannelTx ./artifacts/commonchannel.tx -channelID commonchannel
configtxgen \
	-profile DevelopersChannel \
	-outputCreateChannelTx ./artifacts/developerschannel.tx \
	-channelID developerschannel

__HEADER__ "COMMON CHANNEL ANCHOR PEERS GENERATION"
configtxgen \
	-profile CommonChannel \
	-outputAnchorPeersUpdate ./artifacts/commonchannel.tx \
	-channelID commonchannel \
	-asOrg Managment
configtxgen \
	-profile CommonChannel \
	-outputAnchorPeersUpdate ./artifacts/commonchannel.tx \
	-channelID commonchannel \
	-asOrg WebDepartment
configtxgen \
	-profile CommonChannel \
	-outputAnchorPeersUpdate ./artifacts/commonchannel.tx \
	-channelID commonchannel \
	-asOrg AIDepartment

__HEADER__ "DEVELOPERS CHANNEL ANCHOR PEERS GENERATION"
configtxgen \
	-profile DevelopersChannel \
	-outputAnchorPeersUpdate ./artifacts/developerschannel.tx \
	-channelID developerschannel \
	-asOrg WebDepartment
configtxgen \
	-profile DevelopersChannel \
	-outputAnchorPeersUpdate ./artifacts/developerschannel.tx \
	-channelID developerschannel \
	-asOrg AIDepartment

__HEADER__ "INFRASTRUCTURE RISING"
docker-compose -f ./docker-compose.yaml up -d

__HEADER__ "CHANNELS CONFIGURATION"
export ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/hlf.pixelplex.io/"
ORDERER_CA="${ORDERER_CA}orderers/orderer.hlf.pixelplex.io/msp/tlscacerts/tlsca.hlf.pixelplex.io-cert.pem"
docker exec pphlf-cli \
	peer channel create \
		-o orderer.hlf.pixelplex.io:7050 \
		-c commonchannel \
		-f /opt/gopath/src/github.com/hyperledger/fabric/peer/artifacts/commonchannel.tx \
		--tls \
		--cafile $ORDERER_CA
