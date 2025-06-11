# TON Node Docker

This docker image represents a fully working TON node with 1 validator and a faucet wallet.
Based on [mylocalton-docker](https://github.com/neodix42/mylocalton-docker).

> Use for LOCAL development only!

> It takes about ~60 seconds to provision a container to fully working state.

> Block time is tweaked to be **one second**

## Ports

- `:40004` Lite-server
- `:8081` HTTP-RPC ([toncenter v2](https://toncenter.com/api/v2/#/))
- `:8000` Sidecar
  - `http://ton:8000/status` - health check (ensures node & RPC are running)
  - `http://ton:8000/faucet.json` - returns JSON with credentials for a funded faucet
  - `http://ton:8000/lite-client.json` - returns lite client configuration

## Getting lite client config

Please note that the config returns the IP of localhost (`int 2130706433`).
If you need to have a custom IP, provide `DOCKER_IP=1.2.3.4` as an env variable

```shell
curl -s http://ton:8000/lite-client.json | jq
{
  "@type": "config.global",
  "dht": { ... },
  "liteservers": [
    {
      "id": { "key": "...", "@type": "pub.ed25519" },
      "port": 4443,
      "ip": 2130706433
    }
  ],
  "validator": { ... }
}
```