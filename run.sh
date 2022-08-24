#!/bin/sh
set -e
set -o pipefail
set -u

# Required parameters
: ${URL} ${NET}
set +u

# System config
sysctl -w net.ipv4.ip_forward=1
ulimit -n $(ulimit -n -H)

# Download proxy config
[ -z "$NAME" ] && FILTER='.[0]' || FILTER='.[] | select(.name == env.NAME)'
wget $URL -O - | jq -r "$FILTER" > ss.tmp
[ -s ss.tmp ] || { echo "[ss-tun] proxy not found"; exit 1; }

# Resolve proxy server address to IPv4 address
SS_DOMAIN=$(jq -r '.server // empty' ss.tmp)
[ -z "$SS_DOMAIN" ] && { echo "[ss-tun] empty proxy server"; exit 1; }
SS_IP=$(getent ahostsv4 $SS_DOMAIN | awk 'NR==1{ print $1 }')
[ -z "$SS_IP" ] && { echo "[ss-tun] fail to resolve proxy server address '$SS_DOMAIN'"; exit 1; }

# Rewrite proxy address
jq --arg ip "$SS_IP" '.server = $ip | .local_address = "127.0.0.1" | .local_port = 10809' ss.tmp > ss.json && rm -rf ss.tmp
SS_LOCAL=$(jq -r '(.local_address) + ":" + (.local_port | tostring)' ss.json)

# Proxy config is ready now
echo "[ss-tun] using proxy '$(jq -r '.name // empty' ss.json)' at $SS_IP"

# Start proxy client
ss-local -c ss.json &

# Start tun dev
badvpn-tun2socks --loglevel 3 --tundev proxy --netif-ipaddr 240.0.0.2 --netif-netmask 240.0.0.0 --socks-server-addr $SS_LOCAL --socks5-udp &

sleep 5

# Setup proxy interface
ip addr add 240.0.0.1/4 dev proxy
ifconfig proxy up

# Setup default route for proxy server IP and user's subnet
GW=$(ip route | awk '/default/ { print $3 }')
ip route add $SS_IP via $GW
ip route add $NET via $GW

# Route all other traffics to the proxy interface
ip route del default
ip route add default via 240.0.0.2

echo "[ss-tun] startup completed"

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
