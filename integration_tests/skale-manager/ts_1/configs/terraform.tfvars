do_token = "***REMOVED***"
# instance_size = "s-24vcpu-128gb" # 128gb
# instance_size = "s-16vcpu-64gb" # 64 GB
# instance_size = "s-12vcpu-48gb" # 48 gb
# instance_size = "s-8vcpu-32gb" # 32 gb
# instance_size = "s-6vcpu-16gb" # 16 gb
# instance_size = "s-4vcpu-8gb" # 8 gb
instance_size = "s-2vcpu-4gb" # 4 gb                        # different types for instance on DO

ssh_fingerprints = [
  "9c:8c:a7:46:e5:b4:69:66:b2:bd:2a:33:c4:b3:c5:28",
  "a0:af:b6:37:b6:9e:20:f4:5f:aa:0b:2d:d2:36:d7:aa",
  "98:64:63:cb:64:07:26:7d:d6:0c:30:bd:a5:36:ab:ff",
  "60:51:f0:97:a0:86:55:79:b3:73:af:d9:78:0e:26:7b",
  "77:31:66:89:f2:e8:bb:1b:95:82:6c:12:e1:f7:00:81",
  "2b:e0:24:a8:73:a7:d7:4d:96:5c:d2:d6:44:db:d9:ae",
  "e3:88:89:fd:23:9a:bc:f6:79:a0:b5:16:98:27:09:2a",
  "2e:ae:cc:f5:27:0b:ec:9e:7d:8b:96:cf:3a:58:c4:52",
  "53:5b:67:33:d8:f6:ba:63:e4:15:31:51:da:88:46:c8",
  "3f:aa:28:d3:6e:8d:45:2b:b9:5d:af:f1:c4:c0:c7:b5",
  "6c:c1:ed:e8:8c:85:1d:d3:ad:13:c8:1b:59:a4:e3:0c",
  "7f:8d:ae:0d:2e:61:88:99:95:7f:6d:90:10:b7:48:c9",
  "5f:da:e7:9c:32:e9:4b:47:2e:5c:2e:7f:a3:61:53:e3",
  "66:26:f4:5b:08:b5:13:c8:23:2e:45:32:13:ec:fa:a3",
  "d9:2c:e9:6b:2e:3d:0c:dc:f2:2d:30:8e:24:ee:9f:a9",
  "f4:66:38:10:f7:35:88:81:56:2c:d7:b5:dd:5a:83:f5",
  "0a:11:c7:ff:4b:08:fd:a5:7b:c1:83:1a:a4:26:d3:bf",
  "9d:a7:e7:11:38:8c:3a:1a:92:68:4c:a2:ae:a1:f5:5e",
  "9d:7d:09:30:2f:be:37:60:c8:c5:fc:e1:32:61:05:e8",
  "cc:5c:5f:e9:62:6c:e8:26:1a:f9:aa:0a:a5:bc:2f:16",
  "a5:00:3f:9e:84:fc:fc:47:cf:ab:93:da:8c:52:e0:ce",        # Jenkins key
  "34:8d:b8:89:d9:fa:ef:3a:9a:07:98:a7:fb:53:0a:92",        # debug PC
  "99:9b:d1:09:4b:f0:8e:2f:f0:b8:2e:b5:46:96:e0:f1"
]                                                           # add your fingerprint if absent
region = "sfo2"
volume_region = "sfo2"
volume_size = 300                                            # size of mount volume