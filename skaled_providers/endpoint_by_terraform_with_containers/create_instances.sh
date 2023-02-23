# source it!

# params:
# NUM_NODES - number of hosts to launch
# SUFFIX - nodes "batch" ID

# returns
# tf/output.json

export NUM_NODES="${NUM_NODES:-4}"

cd tf
if [[ ! -f ~/.ssh/id_rsa ]]
then
	ssh-keygen -f ~/.ssh/id_rsa -N ""
fi
cat ~/.ssh/id_rsa.pub >>tf_scripts/scripts/authorized_keys
# allow something to root too (for access to /skale_node_data)
sudo mkdir /root/.ssh || true
sudo cp ~/.ssh/id_rsa* /root/.ssh
./create.sh $SUFFIX
cd ..
