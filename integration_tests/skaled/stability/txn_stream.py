#!/usr/bin/python3

import sys
import pickle
import binascii
import time
import concurrent.futures
import web3
from web3.auto import w3

# transparently and synchronously accesses multiple endpoints
class EthProxy:

    def __init__(self, urls):
        self._urls = urls
        self._eth = None

    def connect_eth(self, timeout = 1):
        urls = self._urls
        while True:
            for u in urls:
                print(f"Accessing {u}...", end='', flush=True)
                provider = web3.Web3.HTTPProvider(u, request_kwargs = {'timeout': 20})
                if not provider.isConnected():
                    print("not connected")
                    continue
                eth = web3.Web3(provider).eth
                try:
                    eth.blockNumber
                except:
                    print("no answer")
                    continue
                print("success")
                return eth
            time.sleep(timeout)

    def __getattr__(self, name):
        while True:
            try:
                val = getattr(self._eth, name)
                if hasattr(val, '__call__'):
                    def f(*args, **kwargs):
                        while True:
                            try:
                                nonlocal val
                                return val(*args, **kwargs)
                            except urllib3.exceptions.HTTPError as ex:
                                print(str(ex))
                                self._eth = self.connect_eth()
                                val = getattr(self._eth, name)
                                continue
                            except Exception as ex:
                                raise ex
                    return f
                else:
                    return val
            except Exception as ex:
                print(str(ex))
                self._eth = self.connect_eth()
                continue

# upon request returns which addresses changed their nonce
class NonceMonitor:
    def __init__(self, eth):
        self._eth = eth

    def start(self):
        self._block_number = self._eth.blockNumber

    def get_changed_addresses(self):
        new_block = self._eth.blockNumber
        if new_block == self._block_number:
            return []
        ret = []
        for b in range(self._block_number+1, new_block+1):
            bb = self._eth.getBlock(b, True)
            for t in bb['transactions']:
                ret.append(t['from'])
        self._block_number = new_block
        return ret

# send dummy transaction
def send(eth, addr, key, nonce):
    transaction = {
        "from": addr,
        "to": addr,
        "value": 1000000000,
        "gas": 21000,
        "gasPrice": 100000,
        "nonce": nonce,
        "chainId": '0x1'
    }
    signed = eth.account.signTransaction(
        transaction,
        private_key=key
    )
    signed_str = "0x" + binascii.hexlify(signed.rawTransaction).decode("utf-8")
    try:
        h = eth.sendRawTransaction(signed_str)
    except Exception as ex:
        print(str(ex))
    return h

def load_addresses_and_keys(num_addresses):
    
    privateKeys = None
    
    with open("keys.all", "rb") as fd:
        privateKeys = pickle.load(fd)
        assert(num_addresses <= len(privateKeys))
    
    address2key = {}
    
    for i in range(num_addresses):
        private_key = privateKeys[i]
        address = w3.eth.account.privateKeyToAccount(
            private_key).address
        address2key[address] = private_key
    
    return address2key

############################# __main__ ########################################

if len(sys.argv) < 2:
    print(f"USAGE: {sys.argv[0]} url1 url2 ...")
    exit(1)

num_addresses = 200

print(f"Loading {num_addresses} accounts...")
address2key = load_addresses_and_keys(num_addresses)
addresses = address2key.keys()

eth = EthProxy(sys.argv[1:])

print(f"Requesting nonces for {num_addresses} accounts...")
address2nonce = {}
for a in addresses:
    address2nonce[a] = eth.getTransactionCount(a)

mon = NonceMonitor(eth)
mon.start()

executor = concurrent.futures.ThreadPoolExecutor(max_workers=5)

time1 = time.time()
sent = 0
received = 0
lost = 0
max_nonce = 0

changed = addresses
received = -len(changed)
while True:
    if len(changed) > 0:
        received += len(changed)
        time2 = time.time()
        print("%.2f txn/s\tqueue = %d txns"%((received)/(time2-time1), sent-lost-received))
        for a in changed:
            try:
                #send(eth, a, address2key[a], address2nonce[a])
                executor.submit(send, eth, a, address2key[a], address2nonce[a])
                print(a, address2nonce[a])
                address2nonce[a] += 1
                sent += 1
                if max_nonce < address2nonce[a]:
                    max_nonce = address2nonce[a]
            except Exception as x:
                print(str(x))
        print("-----------")
    else:
        print("waiting 0.1")
        time.sleep(0.1)

    changed = mon.get_changed_addresses()

    # append changed addresses with lost transactions
    if len(changed) < 2:
        for a in addresses:
            if address2nonce[a] < max_nonce - 10:
                changed.append(a)
                address2nonce[a] -= 1
                lost += 1