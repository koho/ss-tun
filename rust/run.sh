#!/bin/sh
set -e
set -o pipefail
set -u

# Required parameters
: ${SUBNET}
set +u

# System config
sysctl -w net.ipv4.ip_forward=1
ulimit -n $(ulimit -n -H)

if [ "$UPDATE" == "true" ] || [ ! -f ss-sub.json ]; then
  set -u
  : ${URL}
  set +u
  # Download proxy config
  wget $URL -O ss-sub.json
fi

[ -z "$NAME" ] && FILTER='.[0]' || FILTER='first(.[] | select(.name == env.NAME))'
jq -r "$FILTER" ss-sub.json > ss.json
[ -s ss.json ] || { echo "[ss-tun] proxy item not found"; exit 1; }

# Resolve proxy server address to IPv4 address
SS_DOMAIN=$(jq -r '.server // empty' ss.json)
[ -z "$SS_DOMAIN" ] && { echo "[ss-tun] empty proxy server"; exit 1; }
SS_IP=$(getent ahostsv4 $SS_DOMAIN | awk 'NR==1{ print $1 }')
[ -z "$SS_IP" ] && { echo "[ss-tun] fail to resolve proxy server address '$SS_DOMAIN'"; exit 1; }

# Rewrite proxy address
jq --arg ip "$SS_IP" '.server = $ip | .locals = [{"protocol": "tun", "tun_interface_name": "proxy"}]' ss.json > ss.json.tmp && mv ss.json.tmp ss.json

# Proxy config is ready now
TITLE=$(jq -r '.remarks + "(" + .name + ")"' ss.json)
echo "[ss-tun] using proxy '$TITLE' at $SS_IP"

# Start proxy client
sslocal -c ss.json &

sleep 3

# Setup default route for proxy server IP and user's subnet
GW=$(ip route | awk '/default/ { print $3 }')
ip route flush scope global
ip route add $SS_IP via $GW
ip route add $SUBNET via $GW

# Route all other traffics to the proxy interface
ip route add default via $GW metric 1
ip route add default dev proxy metric 0

echo "[ss-tun] startup completed"

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
