# Skaled debug (Process-exporter)

**UI tools for the skaledMonitor**

(To use this tool should be installed Skale-node-provisioning)

**Preconditions:**
- Active  schain 
- Opened ports 9144 and 9256 on the AWS security groups
- Opened ports on the nodes 

**To check status of ports on the nodes run cmd**

`iptables -S | grep "9256"; iptables -S | grep "9144"`

**To open these ports on the nodes run the next cmds on the skale- Supervisor**

`NETWORK=network_name python main.py tools exec "iptables -I INPUT -p tcp --dport 9256 -j ACCEPT"`

`NETWORK=network_name python main.py tools exec "iptables -I INPUT -p tcp --dport 9144 -j ACCEPT"`

## Installation flow

 1. Do steps from [Skale-node-provisioning](https://github.com/skalenetwork/node-provisioning#run-skaled-monitor) “run skaled monitor”.
  
    1.1 Create if not exists virtual env for python 3.7 or higher in the root of the project and activate she before script start

    1.2 Run from the root of the project:
    `pip install -r skale-nodes/ansible/requirements.txt`

    1.3 Copy inventory-template like inventory and fill dev file with absent fields.

    1.4 Add node_ips.json file with all ips what you want (example {"node_name": "node_ip", ..., "node_name": "node_ip"}) to the ansible/files directory. 

    1.5 Go to skale-nodes/ansible dir and run:

    `bash utils/generate_hosts.sh`

    `ansible-playbook -i inventory run_monitor.yaml`
    
 2. Run prom_targets_cli.sh scripts with IP nodes selected to monitor
  
  node_ips.json - file with IP 
  
  *./prom_targets_jq.sh node_ips.json >qa.yml*
  
  ```
    #!/bin/bash

  IPS=($( jq -r '[.[]]|join(" ")' $1 ))

  echo -n '    - targets: ['
  for IP in ${IPS[@]}
  do
    echo -n "'$IP:9144',"
    echo -n "'$IP:9256'"
    if [ "$IP" != "${IPS[-1]}" ]
    then
      echo -n ','
    fi
  done
  echo ']'
  
  ```
 3. Connect to Graphan server with ssh  IP connection (User should have permission to connect)
 
  > Check **jq** program is installed 
  
 4. Upload **qa.yml** on Prometheus (need access grafana_ci)
    example:
    
    ```
        ./prom_targets_cli.sh 1.1.1.1 2.2.2.2 >qa.yml
    ssh -i ~/grafana_ci ubuntu@35.180.187.149 <<- 111
    sudo -i
    cat >/opt/prometheus/conf/qa.yml <<- 222
    $(cat qa.yml)
    222
    docker restart prometheus
    111
    ```
  
  Open http://35.180.187.149:9090/targets to check and search - new nodes should be added and running

  Open http://35.180.187.149:3000/d/wmAUCEqGk/nodes-rss-overview?orgId=1&refresh=5s&from=now-6h&to=now&var-process=All&var-instance=All to check UI monitor for the connected nodes
