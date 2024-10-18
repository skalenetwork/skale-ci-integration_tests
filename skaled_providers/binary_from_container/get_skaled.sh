# source it!

# params:
# SKALED_RELEASE - dockerhub schain container version

# returns
# SKTEST_EXE - path to downloaded binary

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo -- Get schain image --
#SKALED_RELEASE="1.46-develop.45"
docker pull skalenetwork/schain:$SKALED_RELEASE
echo -- Get skale daemon from image --
docker create --name temp_container skalenetwork/schain:$SKALED_RELEASE
docker cp temp_container:/skaled/skaled  $SCRIPT_DIR/skaled
docker rm temp_container
chmod +x $SCRIPT_DIR/skaled

export SKTEST_EXE=$SCRIPT_DIR/skaled