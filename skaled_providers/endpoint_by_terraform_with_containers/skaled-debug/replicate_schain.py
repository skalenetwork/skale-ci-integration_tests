import io
import os
import json
import argparse

import types

import web3

def patch_eth(eth):
    def pauseConsensus(eth, pause):
        eth._provider.make_request("debug_pauseConsensus", [pause])
    def pauseBroadcast(eth, pause):
        eth._provider.make_request("debug_pauseBroadcast", [pause])
    def forceBlock(eth):
        eth._provider.make_request("debug_forceBlock", []);
    def forceBroadcast(eth, h):
        eth._provider.make_request("debug_forceBroadcast", [h]);
    def callSkaleHost(eth, arg):
        res = eth._provider.make_request("debug_callSkaleHost", [arg]);
        return res["result"]
    def getVersion(eth):
        res = eth._provider.make_request("debug_getVersion", []);
        return res["result"]
    def getArguments(eth):
        res = eth._provider.make_request("debug_getArguments", []);
        return res["result"]
    def getConfig(eth):
        res = eth._provider.make_request("debug_getConfig", []);
        return res["result"]
    def getSchainName(eth):
        res = eth._provider.make_request("debug_getSchainName", []);
        return res["result"]

    eth.pauseConsensus = types.MethodType(pauseConsensus, eth)
    eth.pauseBroadcast = types.MethodType(pauseBroadcast, eth)
    eth.forceBlock     = types.MethodType(forceBlock, eth)
    eth.forceBroadcast = types.MethodType(forceBroadcast, eth)
    eth.callSkaleHost  = types.MethodType(callSkaleHost, eth)
    eth.getVersion     = types.MethodType(getVersion, eth)
    eth.getArguments   = types.MethodType(getArguments, eth)
    eth.getConfig      = types.MethodType(getConfig, eth)
    eth.getSchainName  = types.MethodType(getSchainName, eth)

def convert_args(args, config, node_dir):
    me = config['skaleConfig']['nodeInfo']
    arr = args.split(" ")
    res = ""
    i = 0
    while i < len(arr):

        s = arr[i]

        if s == "--ws-port" or s == "--wss-port":
            i += 2
            continue

        res += s + " "
        if s == "--http-port" and 'httpRpcPort' in me:
            res += str(me['httpRpcPort']) + " "
            i += 1
        elif s == "--ws-port" and 'wsRpcPort' in me:
            res += str(me['wsRpcPort']) + " "
            i += 1
        elif s == "--config":
            res += node_dir+"/config.json" + " "
            i += 1
        elif s == "-d" or s == "--db-path":
            res += node_dir + " "
            i += 1
        elif s == "--ipcpath":
            res += node_dir + " "
            i += 1
        i += 1

    return res

def get_eth(url):
    provider = web3.Web3.HTTPProvider(url, request_kwargs={'timeout': 20})
    eth = web3.Web3(provider).eth
    eth._provider = provider
    patch_eth(eth)
    return eth

parser = argparse.ArgumentParser(description='Replicate remote schain locally')
parser.add_argument('url', metavar='<url>', type=str, nargs=1,
                    help='endpoint do get info from')
parser.add_argument('--ips', metavar='<ip>', nargs='+',
                    help='IPs to put in config (need the same amount as in original s-chain)')

args = parser.parse_args()

dest = "."
source_url = args.url[0]
ips = args.ips

eth = get_eth(source_url)

arguments_str = eth.getArguments()
schain_name = eth.getSchainName()
config_str = eth.getConfig()
version_str = eth.getVersion()

config = json.loads(config_str)

print()

print(f"Node {config['skaleConfig']['nodeInfo']['nodeID']} ({config['skaleConfig']['nodeInfo']['nodeName']}) of {len(config['skaleConfig']['sChain']['nodes'])}-node s-chain {schain_name}")
print(f"skaled is: {version_str}")
print(f"runtime argumens are: {arguments_str}")

if len(ips) != len(config['skaleConfig']['sChain']['nodes']):
    print("ERROR: Please provide exact amount of ips as nodes in s-chain!")
    exit()

schain_dir = os.path.abspath(dest+"/"+schain_name)
os.makedirs(schain_dir, exist_ok=True)

with io.open(schain_dir + "/run.sh", "w") as f:
    print("#!/bin/bash -x", file=f)

print("\noriginal endpoints:")
endpoints = []

cnt = 0
for n in config['skaleConfig']['sChain']['nodes']:
    url = f"http://{n['publicIP']}:{int(n['basePort'])+3}"
    endpoints.append(url)
    print(f"{url} => {ips[cnt]}")

    n["ip"] = ips[cnt]
    n["publicIP"] = ips[cnt]

    cnt += 1

print()

cnt = 0
for url in endpoints:

    print(f"Downloading from {url}")
    eth = get_eth(url)
    config_i = json.loads( eth.getConfig() )

    me = config_i['skaleConfig']['nodeInfo']
    try:
        del me["wsRpcPort"]
        del me["wssRpcPort"]
    except:
        pass
    config['skaleConfig']['nodeInfo'] = me
    me["bindIP"] = ips[cnt]

    node_dir = schain_dir + "/" + str(me["nodeID"])
    os.makedirs(node_dir, exist_ok=True)

    with io.open(node_dir + "/config.json", "w") as f:
        json.dump(config, f, indent=1)

    my_args = convert_args(arguments_str, config, node_dir)
    with io.open(schain_dir + "/run.sh", "a+") as f:
        if cnt < len(ips)-1:
            print("DATA_DIR=" + node_dir + " $SKALED " + my_args + "&", file=f)
        else:
            print("DATA_DIR=" + node_dir + " $SKALED " + my_args, file=f)

    cnt += 1

print()
print(f"configuration saved to: {schain_dir}")
print()
