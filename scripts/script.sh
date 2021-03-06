#!/bin/bash
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
STARTED=$(date +%s)
echo
echo " ____    _____      _      ____    _____           _____   ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|         | ____| |___ \  | ____|"
echo "\___ \    | |     / _ \   | |_) |   | |    _____  |  _|     __) | |  _|  "
echo " ___) |   | |    / ___ \  |  _ <    | |   |_____| | |___   / __/  | |___ "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|           |_____| |_____| |_____|"
echo

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}
: ${TIMEOUT:="33"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/ca.example.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org1.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org1.example.com:7051
		fi
	elif [ $1 -eq 2 -o $1 -eq 3 ] ; then
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.org2.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org2.example.com:7051
		fi
	else
		CORE_PEER_LOCALMSPID="Org3MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
		if [ $1 -eq 4 ]; then
			CORE_PEER_ADDRESS=peer0.org3.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org3.example.com:7051
		fi
	fi

	env |grep CORE
}

createChannel() {
	setGlobals 0

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME}1 -f ./channel-artifacts/channel1.tx >&log.txt
	else
		peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME}1 -f ./channel-artifacts/channel1.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel \"${CHANNEL_NAME}1\" creation failed"
	echo "===================== Channel \"${CHANNEL_NAME}1\" is created successfully ===================== "
	echo

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME}2 -f ./channel-artifacts/channel2.tx >&log.txt
	else
		peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME}2 -f ./channel-artifacts/channel2.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel \"${CHANNEL_NAME}2\" creation failed"
	echo "===================== Channel \"${CHANNEL_NAME}2\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	peer channel join -b ${CHANNEL_NAME}$2.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1 $2
	else
		COUNTER=1
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3; do
		setGlobals $ch
		joinWithRetry $ch 1
		echo "===================== PEER$ch joined on the channel \"${CHANNEL_NAME}1\" ===================== "
		sleep 2
		echo
	done
	for ch in 2 3 4 5; do
		setGlobals $ch
		joinWithRetry $ch 2
		echo "===================== PEER$ch joined on the channel \"${CHANNEL_NAME}2\" ===================== "
		sleep 2
		echo
	done
}

installChaincode () {
	for ch in 0 1 2 3; do
		PEER=$ch
		setGlobals $PEER
		peer chaincode install -n mycc02 -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
		res=$?
		cat log.txt
	        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
		echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
		echo
	done
	for ch in 2 3 4 5; do
		PEER=$ch
		setGlobals $PEER
		peer chaincode install -n mycc05 -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05 >&log.txt
		res=$?
		cat log.txt
	        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
		echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
		echo
	done

}

instantiateChaincode () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.example.com:7050 -C ${CHANNEL_NAME}1 -n mycc02 -v 1.0 -c '{"Args":["init","a","250","b","750"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C ${CHANNEL_NAME}1 -n mycc02 -v 1.0 -c '{"Args":["init","a","250","b","750"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '${CHANNEL_NAME}1' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '${CHANNEL_NAME}1' is successful ===================== "
	echo

	PEER=4
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.example.com:7050 -C ${CHANNEL_NAME}2 -n mycc05 -v 1.0 -c '{"Args":["init", "sum", "0"]}' -P "OR ('Org2MSP.member','Org3MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C ${CHANNEL_NAME}2 -n mycc05 -v 1.0 -c '{"Args":["init", "sum", "0"]}' -P "OR ('Org2MSP.member','Org3MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '${CHANNEL_NAME}2' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '${CHANNEL_NAME}2' is successful ===================== "
	echo
}

chaincodeQuery () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel '${CHANNEL_NAME}1'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C ${CHANNEL_NAME}1 -n mycc02 -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '${CHANNEL_NAME}1' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

chaincodeInvoke () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C ${CHANNEL_NAME}1 -n mycc02 -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C ${CHANNEL_NAME}1 -n mycc02 -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '${CHANNEL_NAME}1' is successful ===================== "
	echo
}

c2cQuery () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel '${CHANNEL_NAME}1'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C ${CHANNEL_NAME}2 -n mycc05 -c '{"Args":["query", "mycc02", "sum", "mychannel1"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '${CHANNEL_NAME}2' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

c2cInvoke () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C ${CHANNEL_NAME}2 -n mycc05 -c '{"Args":["invoke","mycc02","sum","mychannel1"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C ${CHANNEL_NAME}2 -n mycc05 -c '{"Args":["invoke","mycc02","sum","mychannel1"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '${CHANNEL_NAME}2' is successful ===================== "
	echo
}

upgradeChaincode () {
	for ch in 0 1 2 3; do
		PEER=$ch
		setGlobals $PEER
		peer chaincode install -n mycc02 -v 2.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
		res=$?
		cat log.txt
	        verifyResult $res "Chaincode installation with v2.0 on remote peer PEER$PEER has Failed"
		echo "===================== Chaincode is installed on remote peer PEER$PEER with v2.0  ===================== "
		echo
	done

	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode upgrade -o orderer.example.com:7050 -C ${CHANNEL_NAME}1 -n mycc02 -v 2.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode upgrade -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C ${CHANNEL_NAME}1 -n mycc02 -v 2.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode Upgrade on PEER$PEER on channel '${CHANNEL_NAME}1' failed"
	echo "===================== Chaincode Upgrade on PEER$PEER on channel '${CHANNEL_NAME}1' is successful ===================== "
	echo
}
## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel


## Install chaincode on Peer0/Org1 and Peer2/Org2
echo "Installing chaincode on org1/peer0..."
installChaincode

#Instantiate chaincode on Peer2/Org2
echo "Instantiating chaincode on org2/peer2..."
instantiateChaincode 2

#Query on chaincode on Peer0/Org1
echo "Querying chaincode on org1/peer0..."
chaincodeQuery 0 250

#Invoke on chaincode on Peer0/Org1
echo "Sending invoke transaction on org1/peer0..."
chaincodeInvoke 0

c2cQuery 2 1000
c2cInvoke 2

upgradeChaincode 0
sleep 20
c2cQuery 2 300
printf "\nTotal execution time : $(($(date +%s)-STARTED)) secs ...\n"

echo
echo "=== All GOOD, Chaincode calling one channel to chaincode on another channel is success ==="
echo

echo " ____     ___    _   _   _____ "
echo "|  _ \   / _ \  | \ | | | ____|"
echo "| | | | | | | | |  \| | |  _|  "
echo "| |_| | | |_| | | |\  | | |___ "
echo "|____/   \___/  |_| \_| |_____|"
echo   

exit 0
