#!/bin/bash

echo
echo "----- integration_tests/skaled/contractsRunningTest/environment.sh ----- begin"

export SKALED_CONTRACTS_TEST=$INTEGRATION_TESTS_DIR/skaled/contractsRunningTest
echo "SKALED_CONTRACTS_TEST = $SKALED_CONTRACTS_TEST"

export SKALE_EXPERIMANTAL=$SKALED_CONTRACTS_TEST/third_party/SkaleExperimental
echo "SKALE_EXPERIMANTAL = $SKALE_EXPERIMANTAL"

curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -

sudo apt-get update -y
sudo apt-get install -y nodejs
sudo ln -s /usr/bin/node /usr/local/bin/node
sudo npm install --global npm
sudo npm install --global color-support
sudo npm install --global yarn
sudo npm install --global node-gyp
sudo yarn global add truffle
sudo yarn global add ganache-cli
which node
node --version
which npm
npm --version
which yarn
yarn --version
which node-gyp
node-gyp --version
which truffle
truffle --version
which ganache-cli
ganache-cli --version

sudo rm -rf ./node-scrypt || true &> /dev/null
git clone https://github.com/barrysteyn/node-scrypt.git &> /dev/null
cd node-scrypt &> /dev/null
git checkout fb60a8d3c158fe115a624b5ffa7480f3a24b03fb &> /dev/null
yarn install &> /dev/null
node-gyp configure build &> /dev/null
cd .. &> /dev/null

cd $SKALE_EXPERIMANTAL/l_sergiy/contractsRunningTest

result=0

yarnpkg install || result=$?
npx truffle compile || result=$?

echo "----- integration_tests/skaled/contractsRunningTest/environment.sh ----- end"
echo

exit $result
