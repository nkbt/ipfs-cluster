# IPFS Cluster Proof of Concept Research Summary

## Introduction

IPFS (InterPlanetary File System) is a distributed file system aiming to connect computers in the same way the internet does. It utilises content-addressing to make the web faster & safer while providing a rich set of APIs.

A key concept in IPFS is treating files as a series of blocks. This enables unique nodes to request only the blocks they don't have when they try to download a file, enabling efficient, high-speed data replication and distribution.

A Dockerized IPFS cluster is a fantastic way to simulate the decentralized and distributed nature of IPFS in a controlled environment.

## Experiment Setup

In this setup, a Docker Compose file is used to build an IPFS cluster with replicated nodes for testing the system's behaviour in a controlled environment. Each service detailed in the Compose file consists of an IPFS node and an IPFS cluster.

Nodes start with the `ipfs` prefix where clusters start with a `cluster` prefix. The first IPFS(`ipfs0`) and its cluster(`cluster0`) form the basic structure. Subsequently, another pair of IPFS(`ipfs1`) and a cluster(`cluster1`) are added as services depending on `ipfs0` and `cluster0`, and the pattern continues for other nodes and clusters.

Each IPFS node runs an IPFS Kubo image, and an IPFS cluster runs the latest IPFS cluster image. Every IPFS node and cluster have their associated configurations and data stored for persistence in the `compose` folder.

## Configuration Parameters

Key configuration parameters within the Docker Compose file include:

- `CLUSTER_REPLICATIONFACTORMIN` and `CLUSTER_REPLICATIONFACTORMAX`, set to `2`, indicate the minimum and maximum number of replicas to be pinned in the cluster. This number will be increased to `5` for the final system.

- `CLUSTER_SECRET` allows the peer to join the cluster. It is read from a shell environment variable of the Docker host and passed into the Docker Compose using Docker's environment variable feature.

- `CLUSTER_IPFSHTTP_NODEMULTIADDRESS` sets the multiaddress of the IPFS daemon API.

- `CLUSTER_CRDT_TRUSTEDPEERS` is set to "*" to indicate that all peers in the cluster are trusted.

- `CLUSTER_MONITORPINGINTERVAL` is set to `2s` for faster peer discovery.

- `CLUSTER_STATESYNCINTERVAL` and `CLUSTER_PINRECOVERINTERVAL` are set to `0m30s` and `1m0s` respectively. These are predefined intervals for state synchronization and pin recovery.

## Environmental Variables

Environmental variables deployed in the services have their configured values located in a `.env` file. This file is integral in incorporating sensitive data or configuration-related data, effectively eliminating the need to hardcode them into the Docker Compose file. Notable environmental variables include:

- `CLUSTER_SECRET`: This is a shared key designed for authorizing communication between nodes. Within an IPFS cluster, only nodes with the correct `CLUSTER_SECRET` can join the cluster.

- `CLUSTER_PEER0`, `CLUSTER_PEER1`, and `CLUSTER_PEER2`: These represent the multiaddresses of the bootstrap cluster peers engaged upon an IPFS node startup. The peers ensure that every node has a recognized set when it joins the network. This often gives room for smoother data management, scalability, and keeping sensitive data out of the main Docker Compose configuration.

The variable `CLUSTER_PEER1` shares the multiaddress for a peer in the IPFS network. In this scenario, it represents `cluster1`. 

Multiaddresses are a self-describing network address format often utilized in making network protocols implementations a breeze and in effect, promoting different network protocols’ interoperability. With a multiaddress in IPFS, you can reach a peer with the following information:

- Network protocol (`/dns4` or `/ip4`),
- Host IP or DNS address (`/cluster1` or `172.19.0.8`),
- Protocol port (`/tcp/9096`), and
- Peer ID (`/p2p/12D3KooWHAbskPGReh6Ysydj1LHHVE5wad5dmnbHMU86hPaE67y7`).

Contrarily, in our setup, the multiaddress is represented with `/dns4`, indicating a DNS address (as opposed to an IP address).

To expand the environment configuration values:

1. Locate the multiaddress of your preferred peer.

    - Every peer has a unique identifier (Peer ID), which is represented as a hash and can be found by running `ipfs-cluster-ctl id` in the node.

    - The IP or DNS address largely depends on how our peers are networked. Within the same network, it could be an `ip4` (IPv4) address or a hostname that channels to the peer's network location.

2. Upon retrieval of these values, you can construct the multiaddress string according to the format provided above.


## The IPFS Bootstrap Script

A script named `ipfs-bootstrap.sh`, executed during the container startup, plays a crucial role in the setup:

- The script starts by running the command `ipfs bootstrap rm --all`, which removes all default bootstrap peers. This is done to ensure that the IPFS node doesn't connect to the public IPFS network during the initialization phase, effectively maintaining network isolation and control over the node's connections upon startup.

- An outlined command, `ipfs bootstrap add "/ip4/$PRIVATE_PEER_IP_ADDR/tcp/4001/ipfs/$PRIVATE_PEER_ID"`, is a placeholder for quickly adding private peers that will not connect to the public IPFS network, further ensuring network isolation.

## Bootstrapping the Cluster Node

In the `cluster6` configuration, the `command` section clearly outlines what to do at container startup.

The command `"daemon --bootstrap ${CLUSTER_PEER1},${CLUSTER_PEER2}"` fires up the IPFS Cluster service. 

The `--bootstrap` flag specifies the multiaddresses of already-running cluster peers to connect with during initialization. For this instance, the `${CLUSTER_PEER1}` and `${CLUSTER_PEER2}` environment variables stand in as arguments. They represent the multiaddresses of other cluster peers, and you can indicate several peers in a comma-separated format to bootstrap with more than one peer. 

By virtue of this configuration, `cluster6` activates and gets looped into the cluster network by setting up connections with nodes identified by `${CLUSTER_PEER1}` and `${CLUSTER_PEER2}`. This method of linking to an existing IPFS Cluster during startup goes by the term "bootstrapping".

After the first startup and successful bootstrapping of an IPFS Cluster, it sustains the information about the bootstrap peers in its `peerstore`. This data is enduring and remains even after restarts. Consequently, on all subsequent restarts or initializations, it becomes unnecessary to use the `--bootstrap` flag since the existing peerstore now contains the details of other peers to establish connections with. Thus, you’d only need to begin the daemon without `--bootstrap` argument.

## Interacting with cluster using `ipfs-cluster-ctl`

This part of the research involves interaction with the `cluster0` node of the IPFS cluster.

Below is the code which outputs the ID of the node, along with its metadata:
```sh
ipfs-cluster-ctl id
12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG | cluster0 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG
    - /ip4/172.19.0.9/tcp/9096/p2p/12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG
  > IPFS: 12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/127.0.0.1/tcp/4001/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/127.0.0.1/udp/4001/quic-v1/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/127.0.0.1/udp/4001/quic-v1/webtransport/certhash/uEiCniItvPONbDnX6ifsNa7MiP4CV-jjtJrzru_vc_6py8g/certhash/uEiCrPqNMfCC4XYbyDPha68-2wZEeM-ToeC2SbS66sHFHow/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/127.0.0.1/udp/4001/quic/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/172.19.0.2/tcp/4001/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/172.19.0.2/udp/4001/quic-v1/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/172.19.0.2/udp/4001/quic-v1/webtransport/certhash/uEiCniItvPONbDnX6ifsNa7MiP4CV-jjtJrzru_vc_6py8g/certhash/uEiCrPqNMfCC4XYbyDPha68-2wZEeM-ToeC2SbS66sHFHow/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/172.19.0.2/udp/4001/quic/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
```

The command `ipfs-cluster-ctl peers ls` provides the list of IPFS peers connected with the node as shown below:
```sh
 ipfs-cluster-ctl peers ls | grep IPFS
  > IPFS: 12D3KooWA65m2TQUv1efWE8z8SsAWy25uDhoEkjG3bSomo6N3tPv
  > IPFS: 12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
  > IPFS: 12D3KooWMQoneaTbBkA38uHCBv34Lbi9izQwdcdWBtEUfEfvNpZc
  > IPFS: 12D3KooWRXvueG4toBs5AGwQyCHKxr2y717gPcmq4KxED88NVMK8
  > IPFS: 12D3KooWNAW3zdKQYvW7iSdECwVENDkYgR5N7Fd358Z83ufxzcc9
  > IPFS: 12D3KooWDE4tcSrXd7B4gz73SczvTx5Qvh5kw7CKDxF3wF3nmw3n

```

We can also get a more detailed list of all peers in the cluster, including their IPFS addresses and connection status (I have cleaned up each peer list of IPFS addresses to reduce the log size):
```sh
ipfs-cluster-ctl peers ls
12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG | cluster0 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG
    - /ip4/172.19.0.9/tcp/9096/p2p/12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG
  > IPFS: 12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
    - /ip4/172.19.0.2/tcp/4001/p2p/12D3KooWMGd54KkrdSvQwEeEH5Af7ZhcuwFi88KyoFgPLLBWuXFy
12D3KooWBiU3i6EGXzxJ86XCntj3SPMbhggcF8qaekC98DHaDA5d | cluster3 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWBiU3i6EGXzxJ86XCntj3SPMbhggcF8qaekC98DHaDA5d
    - /ip4/172.19.0.12/tcp/9096/p2p/12D3KooWBiU3i6EGXzxJ86XCntj3SPMbhggcF8qaekC98DHaDA5d
  > IPFS: 12D3KooWRXvueG4toBs5AGwQyCHKxr2y717gPcmq4KxED88NVMK8
    - /ip4/172.19.0.7/tcp/4001/p2p/12D3KooWRXvueG4toBs5AGwQyCHKxr2y717gPcmq4KxED88NVMK8
12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG | cluster6 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG
    - /ip4/172.19.0.15/tcp/9096/p2p/12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG
  > IPFS: 12D3KooWA65m2TQUv1efWE8z8SsAWy25uDhoEkjG3bSomo6N3tPv
    - /ip4/172.19.0.3/tcp/4001/p2p/12D3KooWA65m2TQUv1efWE8z8SsAWy25uDhoEkjG3bSomo6N3tPv
12D3KooWHAbskPGReh6Ysydj1LHHVE5wad5dmnbHMU86hPaE67y7 | cluster1 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWHAbskPGReh6Ysydj1LHHVE5wad5dmnbHMU86hPaE67y7
    - /ip4/172.19.0.10/tcp/9096/p2p/12D3KooWHAbskPGReh6Ysydj1LHHVE5wad5dmnbHMU86hPaE67y7
  > IPFS: 12D3KooWMQoneaTbBkA38uHCBv34Lbi9izQwdcdWBtEUfEfvNpZc
    - /ip4/172.19.0.4/tcp/4001/p2p/12D3KooWMQoneaTbBkA38uHCBv34Lbi9izQwdcdWBtEUfEfvNpZc
12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K | cluster2 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K
    - /ip4/172.19.0.13/tcp/9096/p2p/12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K
  > IPFS: 12D3KooWDE4tcSrXd7B4gz73SczvTx5Qvh5kw7CKDxF3wF3nmw3n
    - /ip4/172.19.0.8/tcp/4001/p2p/12D3KooWDE4tcSrXd7B4gz73SczvTx5Qvh5kw7CKDxF3wF3nmw3n
12D3KooWLvSNpgsYeRX9RDmjEjR3h5GhuRwirBfWp9iRdc9vdwHA | cluster4 | Sees 5 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/p2p/12D3KooWLvSNpgsYeRX9RDmjEjR3h5GhuRwirBfWp9iRdc9vdwHA
    - /ip4/172.19.0.14/tcp/9096/p2p/12D3KooWLvSNpgsYeRX9RDmjEjR3h5GhuRwirBfWp9iRdc9vdwHA
  > IPFS: 12D3KooWNAW3zdKQYvW7iSdECwVENDkYgR5N7Fd358Z83ufxzcc9
    - /ip4/172.19.0.6/tcp/4001/p2p/12D3KooWNAW3zdKQYvW7iSdECwVENDkYgR5N7Fd358Z83ufxzcc9
```

A file can be added to the cluster using the `ipfs-cluster-ctl add` command. Here, we create a simple text file `hello.txt` and add it to the cluster:
```sh
echo Hello > /tmp/hello.txt

ipfs-cluster-ctl add /tmp/hello.txt
added QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu hello.txt
```

The status of the added file is then checked with the `ipfs-cluster-ctl status` command. It shows how the file is distributed across the cluster:
```sh
ipfs-cluster-ctl status
QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu:
    > cluster6             : REMOTE | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster3             : REMOTE | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster1             : REMOTE | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster2             : PINNED | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster4             : REMOTE | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster0             : PINNED | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
```

Stop ipfs2 who has replica of `QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu`
```sh
docker-compose down ipfs2
[+] Running 4/3
 ✔ Container cluster6    Removed                                                                                       0.8s
 ✔ Container cluster2    Removed                                                                                       0.8s
 ✔ Container ipfs2       Removed                                                                                       0.1s
 ! Network ipfs_default  Resource is still in use                                                                      0.0s
```

After the second IPFS node, which holds a replica of the file, is brought down, the cluster automatically reallocates the pin to keep the replication factor unchanged. Here we see `cluster1` receiving the pin:
```sh
 ipfs-cluster-ctl status
QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu:
    > cluster3             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster1             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster4             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster0             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
```

The logs from `cluster1` show the automatic addition of the pin as per the replication policies.
```sh
INFO	crdt	go-ds-crdt@v0.5.1/crdt.go:562	Number of heads: 0. Current max height: 0. Queued jobs: 0. Dirty: false
INFO	crdt	crdt/consensus.go:245	new pin added: QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu
INFO	crdt	crdt/consensus.go:245	new pin added: QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu
INFO	ipfshttp	ipfshttp/ipfshttp.go:500	IPFS Pin request succeeded: QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for ping: Peer: 12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for ping: Peer: 12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for tag:group: Peer: 12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for tag:group: Peer: 12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for pinqueue: Peer: 12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for pinqueue: Peer: 12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for freespace: Peer: 12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG.
WARN	cluster	ipfs-cluster/cluster.go:492	metric alert for freespace: Peer: 12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K.
INFO	crdt	go-ds-crdt@v0.5.1/crdt.go:562	Number of heads: 1. Current max height: 2. Queued jobs: 0. Dirty: false
```

After restarting `cluster2` and viewing the pin status, we see that the file is pinned on three nodes:
```sh
ipfs-cluster-ctl status
QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu:
    > cluster6             : REMOTE | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster3             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster1             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster2             : PINNED | 2023-10-05T14:35:26Z | Attempts: 0 | Priority: false
    > cluster4             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster0             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
```

However, since the replication factor is two, after a brief delay, the cluster reduces the number of pinned replicas back to two:
```sh
ipfs-cluster-ctl status
QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu:
    > cluster6             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster3             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster1             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster2             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster4             : REMOTE | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
    > cluster0             : PINNED | 2023-10-05T14:37:56Z | Attempts: 0 | Priority: false
```

This behavior can be traced in the logs from `cluster2`, where we see the pin was removed according to the replication policies:
```sh
INFO	cluster	ipfs-cluster/cluster.go:984	Peer added 12D3KooWArCUTCaft8KAM4Mw2AP5WCLsX7SgoibdjRMdeppdAXuG
INFO	cluster	ipfs-cluster/cluster.go:1126	12D3KooWHBsRF3evBUSQVUznVrvYn1dVgxe4Fpz7MtCNu7m3vH2K: joined 12D3KooWPbaKK4q1Uf4vFagi5ANqMccWe2VXgfcSykPmd5b6h7WG cluster
INFO	ipfshttp	ipfshttp/ipfshttp.go:593	IPFS Unpin request succeeded:QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu
INFO	crdt	crdt/consensus.go:245	new pin added: QmY9cxiHqTFoWamkQVkpmmqzBrY3hCBEL2XNu3NtX74Fuu
```

This interaction demonstrates the resilience and dynamic pin allocation of the IPFS cluster, which ensures data redundancy and availability despite node failures.
