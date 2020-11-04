#!/bin/bash

#input: keysN.json and SGX server

N=$1
SGX_URL=$2
CERTS_PATH=/skale_node_data/sgx_certs

uniq=$(date +%s)
for i in $( seq 0 $((N-1)) )
do
    dec=$( jq -r ".privateKey[\"$i\"]" keys$N.json )
    hex=$( echo "obase=16;$dec" | bc )
    
    curl --cert $CERTS_PATH/sgx.crt --key $CERTS_PATH/sgx.key -X POST --data '{"id":1, "jsonrpc":"2.0","method":"importBLSKeyShare","params":{"keyShareName":"BLS_KEY:SCHAIN_ID:'$uniq':NODE_ID:'$((i+1))':DKG_ID:0","keyShare":"0x'$hex'"}}' -H 'content-type:application/json;' $SGX_URL -k
    curl --cert $CERTS_PATH/sgx.crt --key $CERTS_PATH/sgx.key -X POST --data '{"id":1, "jsonrpc":"2.0","method":"generateECDSAKey","params":{}}' -H 'content-type:application/json;' $SGX_URL -k >ecdsa$((i+1)).json
done

echo $uniq >uniq.txt