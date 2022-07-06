#!/usr/bin/python3

import web3.auto
import sys
import types
import time

def patch_eth(eth):
    def pauseConsensus(eth, pause):
        eth._provider.make_request("debug_pauseConsensus", [pause])

    def pauseBroadcast(eth, pause):
        eth._provider.make_request("debug_pauseBroadcast", [pause])

    def forceBlock(eth):
        eth._provider.make_request("debug_forceBlock", [])

    def forceBroadcast(eth, h):
        eth._provider.make_request("debug_forceBroadcast", [h])

    def debugInterfaceCall(eth, arg):
        res = eth._provider.make_request("debug_interfaceCall", [arg])
        return res["result"]

    def getLatestSnapshotBlockNumber(eth):
        res = eth._provider.make_request("skale_getLatestSnapshotBlockNumber", [])
        res = res["result"]
        if res == "earliest":
            res = 0
        else:
            res = int(res)
        return res

    def getSnapshotSignature(eth, bn):
        res = eth._provider.make_request("skale_getSnapshotSignature", [bn])
        if res.get("error", ""):
            return res["error"]
        return res["result"]

    def getSnapshot(eth, block_number):
        res = eth._provider.make_request("skale_getSnapshot", {"blockNumber":block_number})
        if res.get("error", ""):
            return res["error"]
        res = res['result']
        if res.get("error", ""):
            return res["error"]
        return res

    def downloadSnapshotFragment(eth, _from, size, is_binary=False):
        res = eth._provider.make_request("skale_downloadSnapshotFragment", {"from":_from,"isBinary":is_binary,"size":size})
        if res["result"] == "error":
            return res["error"]
        return res["result"]

    eth.pauseConsensus = types.MethodType(pauseConsensus, eth)
    eth.pauseBroadcast = types.MethodType(pauseBroadcast, eth)
    eth.forceBlock = types.MethodType(forceBlock, eth)
    eth.forceBroadcast = types.MethodType(forceBroadcast, eth)
    eth.debugInterfaceCall = types.MethodType(debugInterfaceCall, eth)
    eth.getLatestSnapshotBlockNumber = types.MethodType(getLatestSnapshotBlockNumber, eth)
    eth.getSnapshotSignature = types.MethodType(getSnapshotSignature, eth)
    eth.getSnapshot = types.MethodType(getSnapshot, eth)
    eth.downloadSnapshotFragment = types.MethodType(downloadSnapshotFragment, eth)

def wait_2_snapshots( url ):

  provider = None
  w3 = None

  if url.lower().startswith("http"):
      provider = web3.Web3.HTTPProvider(url, request_kwargs={'timeout': 60})
  elif url.lower().startswith("ws"):
      provider = web3.Web3.WebsocketProvider(url, request_kwargs={'timeout': 60})
  else:
      provider = web3.Web3.IPCProvider(url)

  while not provider.isConnected():
      print(f"Waiting to connect to {url}")
      time.sleep(2)

  print(f"Connected to {url} via object w3")

  w3 = web3.Web3(provider)
  w3.eth._provider = provider
  patch_eth(w3.eth)

  latest_snapshot = -1
  snapshots_count = 0

  worked = False        # exception can occur only once!

  while True:
    try:
        bn1 = w3.eth.blockNumber
        s1 = w3.eth.getLatestSnapshotBlockNumber()
        print(f"block/snapshot: {bn1} {s1}")

        worked = True

        if s1 != latest_snapshot and latest_snapshot != -1:
            snapshots_count+=1

        latest_snapshot = s1

        # wait 2nd snapshot +1 for sure
        if snapshots_count == 3:
            break

    except Exception as e:
        print(str(e))
        assert(not worked)

    time.sleep(10)

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print("USAGE: " + argv[0] + " <URL>")
  else:
    url = sys.argv[1]
  wait_2_snapshots( url )
