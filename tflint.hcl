plugin "google" {
  enabled = true
}

config {
  module          = true
  force           = false
  disabled_by_default = false
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "google_compute_instance_invalid_machine_type" {
  enabled = true
}

rule "google_project_service_not_enabled" {
  enabled = true
}
