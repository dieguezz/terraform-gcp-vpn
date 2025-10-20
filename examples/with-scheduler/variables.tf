variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "firezone_domain" { type = string }
variable "firezone_admin_email" { type = string }
variable "google_workspace_domain" { type = string }

variable "scheduler_start_schedule" { type = string }
variable "scheduler_stop_schedule"  { type = string }
variable "scheduler_timezone"       { type = string }
