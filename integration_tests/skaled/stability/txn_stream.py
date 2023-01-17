#!/usr/bin/python3

import sys
import pickle
import binascii
import time
import concurrent.futures
import web3
import urllib3.exceptions
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

                if u.startswith("http"):
                    provider = web3.Web3.HTTPProvider(u, request_kwargs = {'timeout': 20})
                else:
                    provider = web3.Web3.WebsocketProvider(u)

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
    def __init__(self, eth, addresses):
        self._eth = eth
        self._address2nonce = {}
        self._addresses = addresses

    def start(self):
        self._block_number = self._eth.blockNumber
        for a in self._addresses:
            self._address2nonce[a] = self._eth.getTransactionCount(a)

    def nonce(self, a):
        return self._address2nonce[a]

    def get_changed_addresses(self):
        new_block = self._eth.blockNumber
        if new_block == self._block_number:
            return []
        ret = {}
        print("asking "+str(self._block_number) +" " +str(new_block))
        for b in range(self._block_number+1, new_block+1):
            bb = self._eth.getBlock(b, True)
            cnt = 0
            for t in bb['transactions']:
                if t['from'] in self._address2nonce:
                    ret[t['from']]=True
                    self._address2nonce[t['from']] = t['nonce'] + 1
                    cnt += 1
            print(f"Mined {cnt}")
        self._block_number = new_block
        return ret.keys()

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

############################# __main__ ########################################

if len(sys.argv) < 2:
    print(f"USAGE: {sys.argv[0]} batch_no url1 url2 ...")
    exit(1)

num_addresses = 100
start_address = int(sys.argv[1])*num_addresses

print(f"Loading {num_addresses} accounts...")
address2key = load_addresses_and_keys(start_address, num_addresses)
addresses = address2key.keys()

eth = EthProxy(sys.argv[2:])

mon = NonceMonitor(eth, addresses)
print(f"Requesting nonces for {num_addresses} accounts...")
mon.start()

executor = concurrent.futures.ThreadPoolExecutor(max_workers=32)

time1 = time.time()
sent = 0
received = 0

changed = addresses
received = -len(changed)
while True:
    if len(changed) > 0:
        received += len(changed)
        time2 = time.time()
        print("%.2f txn/s\tqueue = %d txns"%((received)/(time2-time1), sent-received))
        for a in changed:
            try:
                #send(eth, a, address2key[a], mon.nonce(a))
                executor.submit(send, eth, a, address2key[a], mon.nonce(a))
                #print(a, mon.nonce(a))
                sent += 1
            except Exception as x:
                print(str(x))
        print(f"Sent {len(changed)}")
        print("-----------")
    else:
        print("waiting 1")
        time.sleep(1)

    changed = mon.get_changed_addresses()
