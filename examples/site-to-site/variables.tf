variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "firezone_domain" { type = string }
variable "firezone_admin_email" { type = string }
variable "google_workspace_domain" { type = string }

variable "partner_peer_name" { type = string }
variable "partner_peer_ip" { type = string }
variable "partner_local_selectors" { type = list(string) }
variable "partner_remote_selectors" { type = list(string) }
