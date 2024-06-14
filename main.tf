terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

variable "project_id" {
  type        = string
  description = "Your project ID."
}

variable "zone" {
  type        = string
  description = "Scaleway Cloud zone to use."
}

variable "region" {
  type        = string
  description = "Scaleway Cloud region to use."
}

provider "scaleway" {
  project_id = var.project_id
  zone       = var.zone
  region     = var.region
}

variable "dns_zone" {
  description = "Scaleway DNS Zone"
  type        = string
}

variable "instance_type" {
  description = "Type of the instance to be created"
  type        = string
}

variable "operating_system" {
  description = "Operating system for the instance"
  type        = string
}

data "external" "ssh_key" {
  program = ["bash", "-c", "echo \"{\\\"output\\\": \\\"$(ssh-add -L | head -n 1)\\\"}\""]
}

resource "scaleway_iam_ssh_key" "r00t" {
  name       = "r00t"
  public_key = data.external.ssh_key.result.output
}

resource "scaleway_instance_ip" "primary_ipv4" {
  type = "routed_ipv4"
}

resource "scaleway_instance_ip" "primary_ipv6" {
  type = "routed_ipv6"
}

resource "scaleway_domain_record" "wildcard_ipv4" {
  dns_zone = var.dns_zone
  name     = "*"
  type     = "A"
  data     = scaleway_instance_ip.primary_ipv4.address
  ttl      = 300
}

resource "scaleway_domain_record" "wildcard_ipv6" {
  dns_zone = var.dns_zone
  name     = "*"
  type     = "AAAA"
  data     = scaleway_instance_ip.primary_ipv6.address
  ttl      = 300
}

resource "scaleway_instance_ip" "ip" {}

resource "scaleway_instance_volume" "chain_state" {
  type       = "b_ssd"
  name       = "chain-state"
  size_in_gb = 500
}

resource "scaleway_instance_server" "gossamer" {
  type  = var.instance_type
  image = var.operating_system

  enable_ipv6 = true
  ip_ids = [scaleway_instance_ip.primary_ipv4.id, scaleway_instance_ip.primary_ipv6.id]
  additional_volume_ids = [ scaleway_instance_volume.chain_state.id ]

  user_data = {
    cloud-init = file("${path.module}/cloud-init.sh")
  }
}

output "server_ipv4" {
  description = "The IPv4 address of the server"
  value       = scaleway_instance_ip.primary_ipv4.address
}

output "server_ipv6" {
  description = "The IPv6 address of the server"
  value       = scaleway_instance_ip.primary_ipv6.address
}
