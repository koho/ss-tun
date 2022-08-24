# Shadowsocks Tunnel

This Docker image is a combination of [badvpn-tun2socks](https://github.com/ambrop72/badvpn)
and [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev).

## How it works

1. Create a [TUN](https://en.wikipedia.org/wiki/TUN/TAP) device like a VPN software.
2. Modify the routing table and route all traffic to the TUN device.
3. The software `tun2socks` will forward traffic (TCP and UDP) from TUN device to the SOCKS server of `ss-local`.
4. `ss-local` forwards traffic to remote server.

## Usage

```shell
docker pull sstun/ss-tun
```

You must run this container in `--privileged` mode. See [Run](#Run).

### Environment variable

| Env  | Description                                  | Required |
|------|----------------------------------------------|----------|
| URL  | Shadowsocks subscription link                | Yes      |
| NET  | Subnet (CIDR) traffic that goes into tunnel  | Yes      |
| NAME | Use the specific named proxy in subscription | No       |

### Subscription format

The subscription link should download a JSON file that contains an array of proxy object.

```json
[
  {
    "name": "server1",
    "server": "example.com",
    "server_port": 2345,
    "method": "aes-256-gcm",
    "password": "test",
    "use_syslog": false,
    "ipv6_first": false,
    "fast_open": false,
    "reuse_port": false,
    "no_delay": false,
    "mode": "tcp_and_udp"
  }
]
```

### Run

For examples, your local subnet is `192.168.0.0/16`.

```shell
docker run --privileged -e URL=https://example.com/ -e NET=192.168.0.0/16 sstun/ss-tun
```

### Change gateway

Change the default gateway of your host to the container IP. The traffic of your host should go through the Shadowsocks
tunnel in the container now.

## Use cases

- OpenWrt
- RouterOS
