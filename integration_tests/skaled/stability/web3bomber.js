
const Web3 = require('web3');
const fs = require('fs');

const keys_file='keys.json';

const sleep = ( milliseconds ) => { return new Promise( resolve => setTimeout( resolve, milliseconds ) ); };

async function main(){

console.log("Loading private keys from " + keys_file);
const keys = JSON.parse(fs.readFileSync(keys_file, 'utf8'));

console.log("Connecting to " + process.argv[2]);

const web3 = new Web3(process.argv[2]);

var b = await web3.eth.getBlock("latest", true);
console.log("Latest = " + b);

chainId = await web3.eth.getChainId();

console.log("Converting  private keys");

const accounts = [];
for(i in keys.slice(0,1000))
    accounts.push( web3.eth.accounts.privateKeyToAccount( keys[i] ) );
console.log("OK");

function submitRequest(){
	return web3.eth.getBlock("latest", true);
}

console.log("Getting nonces");

var available_i = []
var nonces = {}
for(i in accounts)
	available_i.push(i);
var promises = available_i.map(function(i){
	return web3.eth.getTransactionCount(accounts[i].address).then(function(nonce){
		nonces[i] =  nonce;
	});
});
await Promise.all( promises );
console.log("OK");

async function submitTransaction(){
	if(available_i.length == 0)
		throw Error("No new accounts");
	var i = available_i.pop();
	tr = {
		'nonce': web3.utils.toHex( nonces[i] ),
		'chainId': chainId,
		'to': accounts[i]['address'],
		'value': '0',
		'gas': 21000,
		'gasPrice': '100000'
	};
	signed  = await web3.eth.accounts.signTransaction( tr, accounts[i].privateKey );
	var error = false;
	try{
		r = await web3.eth.sendSignedTransaction(signed.rawTransaction);
		nonces[i]++;
	}catch(ex){
		error = ex;
	}
	available_i.unshift(i);
	if(error)
		throw error;
	return "nobody cares";
}

var submitLoad = submitTransaction;

var recursive_batch;
var i = 0;
var error;

//submitLoad().then(function(){console.log("success");});
//return;

recursive_batch = function(){
	for(var j=0; j<1000; ++j){
		submitLoad().then(function(res){
			//console.log(res);
		}).catch(function(ex){
			console.log(ex);
			error = true;
		});
	}// for
	++i;

	console.log(i+"k");

	if(!error)
		setImmediate( recursive_batch );
	else{
		console.log("Exception: waiting 1 sec");
		setTimeout( function(){
			error = false;
			recursive_batch();
		}, 1000 );
	}
}// batch

recursive_batch();

}

main();
