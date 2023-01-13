#!/bin/python
# dependencies on centos 7
# sudo yum install python-lxml gcc g++ python-pip
# sudo pip install leveldb

# this script dumps the content of a leveldb on
# standard output

import sys
import leveldb

if len(sys.argv) != 2:
   print(str(sys.argv[0])+' needs 1 arguments')
   print('the first argument is the path to a directory containing the leveldb')
   sys.exit(1)

db = leveldb.LevelDB(sys.argv[1])
for k, v in list(db.RangeIter(key_from = None, key_to = None)):
   print("".join("{:02x}".format(c) for c in k), '                ', "".join("{:02x}".format(n) for n in v))

#print(db.Get(b'ead48ec575aaa7127384dee432fc1c02d9f6a22950234e5ecf59f35ed9f6e78d'))

sys.exit(0)
