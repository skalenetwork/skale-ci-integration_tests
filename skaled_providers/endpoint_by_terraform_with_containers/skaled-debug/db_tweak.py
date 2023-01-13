#!/bin/python

import sys
import plyvel

if len(sys.argv) != 3:
   print("USAGE: " + str(sys.argv[0]) + ' <path> <key_hex>')
   sys.exit(1)

db = plyvel.DB(sys.argv[1], create_if_missing = False, compression = None)
key = bytes.fromhex(sys.argv[2])

print("Value:")
try:
    val = db.get(key)
    print("".join("{:02x}".format(c) for c in val))
except:
    print("NOT FOUND")

print("New value:")
new_val = bytes.fromhex(input())
db.put(key, new_val)

val = db.get(key)
print("Result:")
print("".join("{:02x}".format(c) for c in val))
