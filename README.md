# Gossamer Node on Hetzner Cloud

This repo contains Terraform and a cloud-init script for setting up a server on [Hetzner Cloud](https://www.hetzner.com/cloud/) for running a
[Gossamer](https://github.com/ChainSafe/gossamer) node.

In order to use this, you need a Hetzner account, generate an API token for the Cloud API on https://console.hetzner.cloud and one for the DNS API on
https://dns.hetzner.com/.

You probably also want to change a few things in [cloud-init.sh](./cloud-init.sh) related to the user account, dotfile stuff and the hostname for
Grafana in the Caddyfile.

If you don't use ssh-agent, you probably also want to change that part in [main.tf](./main.tf) to read the public key from `~/.ssh/id_rsa.pub` or
whatever the filename is.

Not all necessary steps are automated. After running `terraform apply` successfully, ssh into the box and

* run `systemctl edit caddy.service` and paste:

```
[Service]
EnvironmentFile=/etc/caddy/env
ExecStart=
ExecStart=/usr/bin/caddy run --adapter caddyfile --environ --config /etc/caddy/Caddyfile
ExecReload=
ExecReload=/usr/bin/caddy reload --adapter caddyfile --config /etc/caddy/Caddyfile --force
```

(the `ExecStart`/`ExecReload` stuff is a workaround for caddyserver/caddy#6363)

* create the file `/etc/caddy/env` with the content `HETZNER_DNS_TOKEN=your-token`
* restart Caddy (`systemctl restart caddy.service`)
* run `docker compose build` and `docker compose up` in `~/gossamer`
* profit
