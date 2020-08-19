#!/bin/bash

echo
echo "----- integration_tests/skaled/filestorage/environment.sh ----- begin"

export SKALED_FILESTORAGE_TEST=$INTEGRATION_TESTS_DIR/skaled/filestorage
echo "SKALED_FILESTORAGE_TEST = $SKALED_FILESTORAGE_TEST"

export FILESTORAGE_JS=$SKALED_FILESTORAGE_TEST/third_party/filestorage.js
echo "FILESTORAGE_JS = $FILESTORAGE_JS"

cd $FILESTORAGE_JS

result=0

npm install && npm run generate
result=$?

echo "----- integration_tests/skaled/filestorage/environment.sh ----- end"
echo

exit $result
