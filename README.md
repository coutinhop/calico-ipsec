# calico-ipsec
IPsec for Kubernetes clusters with Calico in IPIP mode. Fork of [adohkan/calico-ipsec](https://github.com/adohkan/calico-ipsec) with fixes and updates to run properly on more current Calico versions.

## Basic set up requirements and steps

1. Cluster running Calico with IPIP encapsulation (`operator.tigera.io/v1` Installation with IPPool `encapsulation` set to `IPIP` [[1]](https://docs.tigera.io/calico/latest/networking/configuring/vxlan-ipip#configure-default-ip-pools-at-install-time), which produces a default IPPool with `ipipMode` set to `Always` [[2]](https://docs.tigera.io/calico/latest/networking/configuring/vxlan-ipip#configure-ip-in-ip-encapsulation-for-all-inter-workload-traffic). `CrossSubnet` mode is not supported.)
2. IPsec authentication set up:
  1. Secrets in `yaml/calico-ipsec-secret.yaml`
  2. `IPSEC_AUTHBY` env var in `yaml/calico-ipsec-daemonset.yaml`
3. Add resources:
  - `kubectl create -f yaml/calico-ipsec-secret.yaml`
  - `kubectl create -f yaml/calico-ipsec-daemonset.yaml`

That's it, this should create a `calico-ipsec-node` daemonset under the `calico-system` namespace, spawning a `calico-ipsec-node-XXXXX` pod for each node in the cluster. These pods will contain the necessary IPsec config to encrypt traffic between cluster nodes.

## IPsec auth simple example (pre-shared key as found [here](https://wiki.strongswan.org/projects/1/wiki/IpsecSecrets)):
```
<IP1> <IP2> ... <IPn> : PSK "v+NkxY9LLZvwj4qCC2o/gGrWDF2d21jL"
``` 
Where \<IPn\> are the IP addresses of all calico-node pods in the cluster.

## Encryption validation

To verify that the nodes are using IPsec encryption:

- Running `ipsec statusall` inside a calico-ipsec-node pod should show the connections under `Routed Connections`
- When there is traffic between nodes, `ipsec statusall` should show `ESTABLISHED` SAs and `INSTALLED` child SAs under `Security Associations`
- Running `tcpdump` (install it first with `apk add tcpdump`) inside the same calico-ipsec-node pod as the traffic source or destination with `tcpdump -i <interface> -xxx -vvv -nnn esp or udp port 4500` should capture the encrypted traffic

## Main fork differences
- Updated alpine base docker image
- Added bypass-lan config (disabling it in order to have encryption between all nodes regardless of them being in the same subnet) to docker image
- Dropped `scheduler.alpha.kubernetes.io/critical-pod` deprecated annotation in favor of `priorityClassName: system-node-critical` in node spec
- Updated pod namespaces from `kube-system` to `calico-system` for compatibility with current calico versions

## Original repo README:
>### Minimal disruption deployment
>
>1. First start Daemonset with `IPSEC_AUTO_PARAM` set to `add` - that will load all the connections without starting them.
>2. Then modify Daemonset environment variable `IPSEC_AUTO_PARAM` to `route` - Strongswan will install kernel traps for traffic and will start the connection automatically.
>
>### MTU overhead
>
>Tunnel configuration `AES_CBC_128/HMAC_SHA2_256_128` - best case overhead is 62, worst 77. MTU on veth should be 1500(base)-20(ipencap)-62(ipsec) so 1418.
>
>### Fixes
>
>- mention firewall rules
