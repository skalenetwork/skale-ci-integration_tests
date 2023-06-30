# source it!

# params:
# IPS array of node IPs
# SKALED_RELEASE

#input: $IP, $I
HOST_PREPARE () {

	scp -o "StrictHostKeyChecking no" config$I.json ubuntu@$IP:/home/ubuntu/config.json
	scp -o "StrictHostKeyChecking no" filebeat.yml ubuntu@$IP:/home/ubuntu
	scp -o "StrictHostKeyChecking no" create_btrfs.sh ubuntu@$IP:/home/ubuntu

	scp -r -o "StrictHostKeyChecking no" skaled-debug/skaled_monitor ubuntu@$IP:/home/ubuntu
	sudo scp -r -o "StrictHostKeyChecking no" /skale_node_data ubuntu@$IP:/home/ubuntu

	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

    sudo apt-get install net-tools

    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

	curl -fsSL https://get.docker.com -o get-docker.sh
	sudo sh get-docker.sh

	sudo docker pull docker.elastic.co/beats/filebeat:7.3.1
	sudo chmod go-w filebeat.yml
	sudo chown root:root filebeat.yml

	sudo BTRFS_DIR_PATH=data_dir BTRFS_FILE_PATH=/dev/xvdd ./create_btrfs.sh
	sudo chown \$USER:\$USER data_dir
    mkdir shared_space
    mkdir shared_space/data

	sudo docker pull skalenetwork/schain:$SKALED_RELEASE

	****

}

I=0
for IP in ${IPS[*]} #:0:11}
do
	I=$((I+1))
	IP=$IP I=$I HOST_PREPARE&
done

wait
