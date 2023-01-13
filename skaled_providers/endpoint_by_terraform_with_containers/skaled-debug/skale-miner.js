const BN = require("bn.js");
const crypto = require("crypto")

const DIFFICULTY = new BN(1);


async function mineGasForTransaction(web3, tx) {
    if(tx.from === undefined || tx.nonce === undefined) {
        throw new Error("Not enough fields for mining gas (from, nonce)")
    }
    if (!tx.gas) {
        tx.gas = await web3.eth.estimateGas(tx)
    }
    let address = tx.from
    let nonce = web3.utils.isHex(tx.nonce) ? web3.utils.hexToNumber(tx.nonce) : tx.nonce;
    let gas = web3.utils.isHex(tx.gas) ? web3.utils.hexToNumber(tx.gas) : tx.gas;
    tx.gasPrice = mineFreeGas(gas, address, nonce, web3);
}


function mineFreeGas(gasAmount, address, nonce, web3) {
    console.log('Mining free gas: ', gasAmount);
    let nonceHash = new BN(web3.utils.soliditySha3(nonce).slice(2), 16)
    let addressHash = new BN(web3.utils.soliditySha3(address).slice(2), 16)
    let nonceAddressXOR = nonceHash.xor(addressHash)
    let maxNumber = new BN(2).pow(new BN(256)).sub(new BN(1));
    let divConstant = maxNumber.div(DIFFICULTY);
    let candidate;
    while (true){
        candidate = new BN(crypto.randomBytes(4).toString('hex'), 16);
        let candidateHash = new BN(web3.utils.soliditySha3(candidate).slice(2), 16);
        let resultHash = nonceAddressXOR.xor(candidateHash);
        let externalGas = divConstant.div(resultHash).toNumber();
        if (externalGas >= gasAmount) {
            break;
        }
    }
    return candidate.toString();
}

exports.mineGasForTransaction = mineGasForTransaction
