const Web3 = require('web3');
const mineGasForTransaction = require('./skale-miner').mineGasForTransaction;

if( process.argv.length != 4 ) {
    console.log("USAGE: " + process.argv[0] + " " + process.argv[1]  + " <endpoint_url> <private_key>");
    process.exit(1);
}

async function main() {

    const endpoint_url = process.argv[2];
    const private_key  = process.argv[3];

    const web3 = new Web3(endpoint_url);

    let address = web3.eth.accounts.privateKeyToAccount(private_key)['address'];

    let nonce = await web3.eth.getTransactionCount(address)

    let tx = {
        from: address,
        to: address,
        value: '0',
        gas: web3.utils.toHex('21000'),
        nonce: nonce,
    };

    mineGasForTransaction(web3, tx);

    console.log(tx);

    try {

        let signed = await web3.eth.accounts.signTransaction(tx, private_key);

        let receipt = await web3.eth.sendSignedTransaction(signed.rawTransaction);

        console.log(receipt);

    } catch ( ex ) {
        console.log( ex );
    }

}// main

main();
