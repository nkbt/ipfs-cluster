#!/bin/sh

set -ex
ipfs bootstrap rm --all

# Add private peers for quicker bootstrap if necessary
# ipfs bootstrap add "/ip4/$PRIVATE_PEER_IP_ADDR/tcp/4001/ipfs/$PRIVATE_PEER_ID"

ipfs config --json Swarm.AddrFilters '["/ip4/172.18.0.0/ipcidr/16"]'
