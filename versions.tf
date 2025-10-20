############################################################
# Terraform & Provider version constraints
############################################################
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      # Align with lock file (7.4.0). Allow any non‑breaking 7.x release; block future 8.x until reviewed.
      version = ">= 7.4.0, < 8.0.0"
    }
  }
}

# Rationale:
# - Previously constrained to 5.x which conflicts with the initialized provider (7.4.0 in .terraform.lock.hcl).
# - Using a floor of 7.4.0 ensures reproducibility with features / schema introduced up to that minor.
# - Upper bound (<8.0.0) avoids unexpected breaking changes from a future major.
# - To deliberately upgrade: bump the lower bound to the tested minor (e.g. >=7.8.0) after running acceptance tests.
