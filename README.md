# Gossamer Node on Hetzner Cloud

This repo contains Terraform and a cloud-init script for setting up a server on [Hetzner Cloud](https://www.hetzner.com/cloud/) for running a
[Gossamer](https://github.com/ChainSafe/gossamer) node.

In order to use this, you need a Hetzner account, generate an API token for the Cloud API on https://console.hetzner.cloud and one for the DNS API on
https://dns.hetzner.com/.

You probably also want to change a few things in [cloud-init.sh](./cloud-init.sh) related to the user account, dotfile stuff and the hostname for
Grafana in the Caddyfile.

If you don't use ssh-agent, you probably also want to change that part in [main.tf](./main.tf) to read the public key from `~/.ssh/id_rsa.pub` or
whatever the filename is.

After running `terraform apply` successfully, ssh into the box and run the following in `~/gossamer`

* `docker compose build`
* `docker compose up`

