import sys
import time
import web3
import pickle
import binascii
from web3.auto import w3

start_address = 0
num_addresses = 1000
addresses = []
address2key = {}
eth=None

def load_addresses_and_keys(start_address, num_addresses):

    privateKeys = None

    with open("keys.all", "rb") as fd:
        privateKeys = pickle.load(fd)
        assert(start_address+num_addresses <= len(privateKeys))

    address2key = {}

    for i in range(start_address, start_address+num_addresses):
        private_key = privateKeys[i]
        address = w3.eth.account.privateKeyToAccount(
            private_key).address
        address2key[address] = private_key

    return address2key

def transaction_obj(**kwargs):

    global addresses
    assert len(addresses) > 0
    global eth
    global address2key

    _from = kwargs.get("_from", 0)
    from_addr = addresses[_from]
    to = kwargs.get("to", 1)
    value = kwargs.get("value", 1000 * 1000 * 1000)
    nonce = kwargs.get("nonce", eth.getTransactionCount(from_addr))
    data = kwargs.get("data", "0x")
    gas = int(kwargs.get("gas", 21000))
    chain_id = kwargs.get("chain_id", 1)

    if type(to) is str:
        to_addr = to
    else:
        to_addr = addresses[to]

    transaction = {
        "from": from_addr,
        "to": to_addr,
        "value": value,
        "gas": gas,
        "gasPrice": 1000000,
        "nonce": nonce,
        "data": data,
        "chainId": chain_id
    }
    if "code" in kwargs:
        transaction["code"] = kwargs["code"]

    signed = w3.eth.account.sign_transaction(
        transaction,
        private_key=address2key[from_addr]
    )
    return "0x" + binascii.hexlify(signed.rawTransaction).decode("utf-8")


if len(sys.argv) < 2:
    print(f"USAGE: {sys.argv[0]} url start_address(0) num_addresses(1000)")
    exit(1)

url = sys.argv[1]
start_address = int(sys.argv[2]) if len(sys.argv)>2 else start_address
num_addresses = int(sys.argv[3]) if len(sys.argv)>3 else num_addresses

print(f"Loading {num_addresses} accounts at {start_address}...")
address2key = load_addresses_and_keys(start_address, num_addresses)
addresses = list(address2key.keys())

print(f"Accessing {url}...", end='', flush=True)

if url.startswith("http"):
    provider = web3.Web3.HTTPProvider(url, request_kwargs = {'timeout': 20})
else:
    provider = web3.Web3.WebsocketProvider(url)

if not provider.isConnected():
    print("not connected")
    exit(1)
eth = web3.Web3(provider).eth
try:
    eth.blockNumber
except:
    print("no answer")
    exit(1)
print("success")

chainId = eth.chainId
print(f"chainId = {chainId}")

#pragma solidity >=0.4.10 <0.7.0;
#
#
#contract StorageFiller{
#    
#    mapping (bytes32 => bytes32) public store;
#    
#    fallback() external payable {
#        uint n = msg.value;
#        for(uint32 i=0; i<n; ++i){
#            bytes32 v = keccak256(abi.encodePacked(block.number)) ^ keccak256(abi.encodePacked(i));
#            store[v] = v;
#        }// for
#        
#    }// fallback
#}

bytecode = "608060405234801561001057600080fd5b50610162806100206000396000f3fe6080604052600436106100225760003560e01c8063654cf88c146100c557610023565b5b600034905060008090505b818163ffffffff1610156100c157600081604051602001808263ffffffff1663ffffffff1660e01b81526004019150506040516020818303038152906040528051906020012043604051602001808281526020019150506040516020818303038152906040528051906020012018905080600080838152602001908152602001600020819055505080600101905061002e565b5050005b3480156100d157600080fd5b506100fe600480360360208110156100e857600080fd5b8101908080359060200190929190505050610114565b6040518082815260200191505060405180910390f35b6000602052806000526040600020600091509050548156fea26469706673582212206ed9022abf7d78f2cb65c1d192422a8be170d1788bd35c79c90c95f5580f7d8964736f6c63430006060033"

raw_deploy = transaction_obj(gas=180000, data=bytecode, value=0, to="", chain_id=chainId)
deploy_hash = eth.sendRawTransaction(raw_deploy)
deploy_receipt = None
while not deploy_receipt:
    try:
        deploy_receipt = eth.getTransactionReceipt(deploy_hash)
    except:
        pass
    time.sleep(0.1)

print(str(deploy_receipt))

contractAddress = deploy_receipt["contractAddress"]
print(f"contractAddress={contractAddress}")
code = eth.getCode(contractAddress)
print(f"code={code}")

count = 0
while True:

  for i in range(num_addresses):
    raw_call = transaction_obj(gas=181000 + 99000, _from=i, to=contractAddress, value=1, chain_id=chainId)
    call_hash = eth.sendRawTransaction(raw_call)
    call_receipt = None
    print(f"from = {i}")

  # wait only last
  while not call_receipt:
    try:
      call_receipt = eth.getTransactionReceipt(call_hash)
    except:
      pass
    time.sleep(0.1)

  count += 1
  print(f"COUNT = {count} batches")
