# source it!

# params:
# NUM_NODES - number of hosts to launch
# SUFFIX - nodes "batch" ID
# HISTORIC - true or false

# returns
# tf/output.json

export NUM_NODES="${NUM_NODES:-4}"

cd tf
if [[ ! -f ~/.ssh/id_rsa ]]
then
	ssh-keygen -f ~/.ssh/id_rsa -N ""
fi

if ! grep -Fxq "$USER@$HOSTNAME" tf_scripts/scripts/authorized_keys
then
    cat ~/.ssh/id_rsa.pub >>tf_scripts/scripts/authorized_keys
fi

# allow something to root too (for access to /skale_node_data)
sudo mkdir /root/.ssh || true
sudo cp ~/.ssh/id_rsa* /root/.ssh
if $HISTORIC
then
    # HACK +1 because inside create.sh NUM_NODES is divided by 2
    NUM_NODES="$((${NUM_NODES:-4}+2))" ./create.sh $SUFFIX
else
    NUM_NODES="${NUM_NODES:-4}" ./create.sh $SUFFIX
fi
cd ..
