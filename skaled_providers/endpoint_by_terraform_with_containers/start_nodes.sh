# source it!

# params:
# IPS array of node IPs
# SKALED_RELEASE - dockerhub schain container version
# SGX_URL

#input: $IP, $I
HOST_START () {
	ssh -o "StrictHostKeyChecking no" ubuntu@$IP <<- ****

	sudo docker run -d --network host -u root -e FILEBEAT_HOST=3.17.12.121:5000 -v /home/ubuntu/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro -v /var/lib/docker:/var/lib/docker:ro -v /var/run/docker.sock:/var/run/docker.sock docker.elastic.co/beats/filebeat:7.3.1

	for J in {0..0}
	do

		#mv config.json data_dir/config.json
		mkdir data_dir/\$J

		sed "s/1231,/1\$((2+J))31,/g" config.json > data_dir/\$J/config.json

		#sudo docker start skale-ci-\$J
		sudo docker run -d -e catchupIntervalMs=60000 --cap-add SYS_ADMIN --name=skale-ci-\$J -v /home/ubuntu/shared_space:/shared_space -v /home/ubuntu/skale_node_data:/skale_node_data -v /home/ubuntu/data_dir/\$J:/data_dir -p 1\$((2+J))31-1\$((2+J))39:1\$((2+J))31-1\$((2+J))39/tcp -e DATA_DIR=/data_dir -i -t --stop-timeout 300 --restart=always -m 1g skalenetwork/schain:$SKALED_RELEASE --http-port 1\$((2+J))34 --ws-port 1\$((2+J))33 --config /data_dir/config.json -d /data_dir --ipcpath /data_dir -v 4 --web3-trace --enable-debug-behavior-apis --aa no --sgx-url ${SGX_URL} --shared-space-path /shared_space/data

	done

	cd skaled_monitor
	sudo ./node-side-monitor.sh </dev/null 2>/dev/null >/dev/null &
	cd ..

	****
}

I=0
for IP in ${IPS[*]} #:0:11}
do
	I=$((I+1))
	IP=$IP I=$I HOST_START&
done

wait

sleep 30	# sometimes transaction script cannot connect, so wait
