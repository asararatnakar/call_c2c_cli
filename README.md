# Chaincode calling on one channel to a chaincode on another channel
Calling a chaincode (ex : example05)on one channel-2 to a chaincode (ex: eample02) on another channel-1


How to run Sample chaincode example05 calling example02


* clone fabric code
```
git clone https://github.com/hyperledger/fabric.git
```

* Build images
This step is **optional** and can use getting started scripts from fabric to download the publishes docker images
Refer [this](http://hyperledger-fabric.readthedocs.io/en/latest/getting_started.html#download-the-artifacts-and-binaries-pull-the-docker-images)
```
make docker
```

* clone this repo to run the test

```
git clone https://github.com/asararatnakar/call_c2c_cli
cd call_c2c_cli
```


* Run the script

```
 ./network_setup.sh 
```

This script 
* clears the docker conatiners / dangling docker images 
* clears all the certs and channel artifacts 
* created required artifacts (certs + channel config transaction)
* starts the local network

At the end of the execution , you would see the following output

```

Total execution time : 60 secs ...

=== All GOOD, Chaincode calling one channel to chaincode on another channel is success ===

 ____     ___    _   _   _____ 
|  _ \   / _ \  | \ | | | ____|
| | | | | | | | |  \| | |  _|  
| |_| | | |_| | | |\  | | |___ 
|____/   \___/  |_| \_| |_____|
```
