#!/bin/bash

echo
echo "----- integration_tests/skaled/filestorage/test.sh ----- begin"

TEST_NAME=$1


export FILESTORAGE_TEST=$INTEGRATION_TESTS_DIR/skaled/filestorage
echo "FILESTORAGE_TEST = $FILESTORAGE_TEST"

export FILESTORAGE_JS=$FILESTORAGE_TEST/third_party/filestorage.js
echo "FILESTORAGE_JS = $FILESTORAGE_JS"

. $SKALED_PROVIDER/get_skaled.sh $FILESTORAGE_TEST/accounts.json

cd $FILESTORAGE_JS

export SKALE_ENDPOINT=$ENDPOINT_URL

# from accounts.json
export SCHAIN_OWNER_PK="1016316fe598b437cfd518c02f67467385b018e61fd048325c7e7c9e5e07cd2a"
export PRIVATEKEY="1016316fe598b437cfd518c02f67467385b018e61fd048325c7e7c9e5e07cd2a"
export FOREIGN_PRIVATEKEY="14e7e34f77749217477a6c36ddff3f5b5f217c67782dd7cc4ec4c0f9997f968b"

result=0
npm test
result=$?

$SKALED_PROVIDER/free_skaled.sh

echo "----- integration_tests/skaled/filestorage/test.sh ----- end"
echo

exit $result
