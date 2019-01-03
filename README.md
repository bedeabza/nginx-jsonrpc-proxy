# Nginx HTTP -> JSON-RPC proxy

Docker image for exposing a JSON-RPC API over simple HTTP. A simple whitelist/blacklist mechanism is available to ensure only certain RPC methods are exposed.

The intended use of the proxy is for publicly available JSON-RPC APIs, for example, that of a Gincoin, or Bitcoin full node.

The Lua programming language is used (via [Openresty](https://openresty.org/)) for translating the request from an simple HTTP request to a JSON-RPC call. The [Openresty](https://openresty.org/) runtime uses JIT (Just In Time) compilation of the code, so it adds almost no overhead on the standard Nginx reverse proxy. 

## Examples

The examples use the Gincoin RPC, but any JSON-RPC 1.0 standard adhering server can be proxied.

Run a simple container proxying requests to an existing Gincoin daemon running as the "daemon" named service.

```bash
# Starts the proxy on http://localhost
# The following requests will now work:
#   - http://localhost/getbestblockhash
#   - http://localhost/getblock/000000000003a357b58e73e6d99b57f33a7eddbeeb1a0f23aab6d096af3d16e0 

docker run --rm -d \
    -e "JSONRPC_PROXY_PORT=80" \
    -e "JSONRPC_PROXY_BACKEND=daemon:10211" \
    -e "JSONRPC_PROXY_AUTHORIZATION=Basic dXNlcjpwYXNzd29yZA==" \
    -e "JSONRPC_PROXY_WHITELIST=getbestblockhash,getblock" \
    -e "JSONRPC_PROXY_DEFAULT_METHOD=getbestblockhash" \
    bedeabza/nginx-jsonrpc-proxy
```

Example docker-compose.yaml

```bash
version: '3'

services:
  daemon:
    image: gincoin/wallet-gincoin
  proxy:
    image: bedeabza/nginx-jsonrpc-proxy
    depends_on:
      - daemon
    ports:
      - 80:80
    environment:
      - JSONRPC_PROXY_PORT=80
      - JSONRPC_PROXY_BACKEND=daemon:80
      - JSONRPC_PROXY_WHITELIST=getinfo,getrawtransaction,masternodelist
      - JSONRPC_PROXY_DEFAULT_METHOD=getinfo
      - JSONRPC_PROXY_AUTHORIZATION=Basic dXNlcjpwYXNzd29yZA==
```

Start the node and proxy with ```docker-compose up -d``` and now the 3 whitelisted RPC methods are available at ```http://localhost/getinfo``` and similar endpoints.

## Build

```bash
git clone https://github.com/bedeabza/nginx-jsonrpc-proxy.git
cd nginx-jsonrpc-proxy
docker build -t proxy .
```

## Credits

Thanks to the Rsk team for the Lua base of this proxy: https://github.com/rsksmart/rskj/wiki/Nginx-Proxy-Server-for-JSONRPC-Calls#openrestynginx-proxy-for-node-servers