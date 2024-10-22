# source it!

# params:
# IPS array of node IPs
# REMOTE_USER
# HISTORIC & HISTORIC_IP
# SKALED_RELEASE

REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOME="/home/$REMOTE_USER"
if [ "$REMOTE_USER" = "root" ]
then
  REMOTE_HOME="/root"
fi

#input: $IP, $I
HOST_PREPARE () {

	scp -o "StrictHostKeyChecking no" config$I.json $REMOTE_USER@$IP:$REMOTE_HOME/config.json

	scp -o "StrictHostKeyChecking no" filebeat.yml $REMOTE_USER@$IP:$REMOTE_HOME

	scp -o "StrictHostKeyChecking no" create_btrfs.sh $REMOTE_USER@$IP:$REMOTE_HOME

	scp -r -o "StrictHostKeyChecking no" skaled-debug/skaled_monitor $REMOTE_USER@$IP:$REMOTE_HOME
	sudo scp -r -o "StrictHostKeyChecking no" /skale_node_data $REMOTE_USER@$IP:$REMOTE_HOME

	ssh -o "StrictHostKeyChecking no" $REMOTE_USER@$IP <<- ****

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
	#sudo BTRFS_DIR_PATH=data_dir BTRFS_FILE_PATH=/dev/nvme1n1 ./create_btrfs.sh
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

if $HISTORIC
then
	scp -o "StrictHostKeyChecking no" config-historic.json $REMOTE_USER@$HISTORIC_IP:$REMOTE_HOME/config.json
    IP=$HISTORIC_IP I=100 SKALED_RELEASE="${SKALED_RELEASE}-historic" HOST_PREPARE&
fi

wait
