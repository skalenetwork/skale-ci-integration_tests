#!/usr/bin/python3

import sys
import leveldb

interesting_keys = [
b"best",
b"pieceUsageBytes",
b"totalStorageUsed",
b"ead48ec575aaa7127384dee432fc1c02d9f6a22950234e5ecf59f35ed9f6e78d",
b"safeLastExecutedTransactionHash",
b"safeLastTransactionReceipts",
b"storageUsed"
]

def simple_extract_string(input):
    length = len(input)
    if length == 0:
        return "error: input is null"
    prefix = input[0]
    if prefix <= 0x7f:
        return "{:02x}".format(input[0])
    elif prefix <= 0xb7 and length > prefix - 0x80:
        strLen = prefix - 0x80
        return "".join("{:02x}".format(c) for c in input[1:strLen+1])
    else:
        return "error: too long string"

argv_offset = 1
if len(sys.argv)>1 and sys.argv[1]=="-q":
    interesting_keys.extend((s.encode() for s in sys.argv[2].split(",")))
    try:
        interesting_keys.extend((bytearray.fromhex(s) for s in sys.argv[2].split(",")))
    except:
        pass
    argv_offset += 2

for path in sys.argv[argv_offset:]:
    print(path)
    db = leveldb.LevelDB(path)
    for key in interesting_keys:
        for key2 in [key, b"\0"+key, b"\1"+key]:
            try:
                value = db.Get(key2)
                try:
                    value = '"'+value.decode('utf-8')+'"'
                except:
                    value = "".join("{:02x}".format(c) for c in value)
                    
                print(key2, value)
            except Exception as ex:
                pass
    try:
        best = db.Get(b"\1best")
        best_details= db.Get(b"\1"+best+b"\0")
        print("best:")
        print("".join("{:02x}".format(c) for c in best_details))
        num = simple_extract_string(best_details[1:])
        print("best block number:", num)
    except:
        pass

    print()
