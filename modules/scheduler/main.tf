# ==============================================================================
# SCHEDULER MODULE - MAIN CONFIGURATION
#
# Automates VPN instance start/stop based on business hours to optimize costs.
# 
# This module creates:
# - Service Account with minimal permissions for instance management
# - Cloud Functions (Gen2) to start/stop the instance
# - Cloud Scheduler jobs to trigger functions on schedule
# - Required IAM bindings
# ==============================================================================

terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.4.0, < 8.0.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# ==============================================================================
# SERVICE ACCOUNT FOR CLOUD FUNCTIONS
# ==============================================================================

resource "google_service_account" "scheduler_sa" {
  count = var.enable_scheduling ? 1 : 0

  account_id   = "${var.resource_prefix}-sa"
  display_name = "VPN Instance Scheduler Service Account"
  description  = "Service account for Cloud Functions to manage VPN instance lifecycle"
  project      = var.project_id
}

# Grant permissions to start/stop instances
resource "google_project_iam_member" "scheduler_compute_admin" {
  count = var.enable_scheduling ? 1 : 0

  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# Allow service account to create tokens for itself (required for OIDC authentication)
resource "google_service_account_iam_member" "scheduler_token_creator" {
  count = var.enable_scheduling ? 1 : 0

  service_account_id = google_service_account.scheduler_sa[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# ==============================================================================
# CLOUD STORAGE BUCKET FOR FUNCTION SOURCE CODE
# ==============================================================================

resource "google_storage_bucket" "function_source" {
  count = var.enable_scheduling ? 1 : 0

  name     = "${var.project_id}-${var.resource_prefix}-functions"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = true

  labels = var.common_labels

  encryption {
    default_kms_key_name = var.bucket_kms_key != "" ? var.bucket_kms_key : null
  }
}

# ==============================================================================
# CLOUD FUNCTION - START INSTANCE
# ==============================================================================

# Package the start function source code
data "archive_file" "start_function_source" {
  count = var.enable_scheduling ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/functions/.tmp/start-instance.zip"
  source_dir  = "${path.module}/functions/start-instance"
}

# Upload start function source to GCS
resource "google_storage_bucket_object" "start_function_source" {
  count = var.enable_scheduling ? 1 : 0

  name   = "start-instance-${data.archive_file.start_function_source[0].output_md5}.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = data.archive_file.start_function_source[0].output_path
}

# Create Cloud Function to start instance
resource "google_cloudfunctions2_function" "start_instance" {
  count = var.enable_scheduling ? 1 : 0

  name     = "${var.resource_prefix}-start"
  location = var.region
  project  = var.project_id

  description = "Starts the VPN instance for business hours"

  build_config {
    runtime     = var.function_runtime
    entry_point = "start_instance_handler"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source[0].name
        object = google_storage_bucket_object.start_function_source[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = var.function_memory
    timeout_seconds       = var.function_timeout
    service_account_email = google_service_account.scheduler_sa[0].email

    environment_variables = {
      PROJECT_ID    = var.project_id
      ZONE          = var.zone
      INSTANCE_NAME = var.instance_name
    }
  }

  labels = var.common_labels
}

# Allow Cloud Scheduler to invoke the start function (Cloud Functions Gen2 uses Cloud Run)
resource "google_cloud_run_service_iam_member" "start_invoker" {
  count = var.enable_scheduling ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.start_instance[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# ==============================================================================
# CLOUD FUNCTION - STOP INSTANCE
# ==============================================================================

# Package the stop function source code
data "archive_file" "stop_function_source" {
  count = var.enable_scheduling ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/functions/.tmp/stop-instance.zip"
  source_dir  = "${path.module}/functions/stop-instance"
}

# Upload stop function source to GCS
resource "google_storage_bucket_object" "stop_function_source" {
  count = var.enable_scheduling ? 1 : 0

  name   = "stop-instance-${data.archive_file.stop_function_source[0].output_md5}.zip"
  bucket = google_storage_bucket.function_source[0].name
  source = data.archive_file.stop_function_source[0].output_path
}

# Create Cloud Function to stop instance
resource "google_cloudfunctions2_function" "stop_instance" {
  count = var.enable_scheduling ? 1 : 0

  name     = "${var.resource_prefix}-stop"
  location = var.region
  project  = var.project_id

  description = "Stops the VPN instance after business hours"

  build_config {
    runtime     = var.function_runtime
    entry_point = "stop_instance_handler"

    source {
      storage_source {
        bucket = google_storage_bucket.function_source[0].name
        object = google_storage_bucket_object.stop_function_source[0].name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = var.function_memory
    timeout_seconds       = var.function_timeout
    service_account_email = google_service_account.scheduler_sa[0].email

    environment_variables = {
      PROJECT_ID    = var.project_id
      ZONE          = var.zone
      INSTANCE_NAME = var.instance_name
    }
  }

  labels = var.common_labels
}

# Allow Cloud Scheduler to invoke the stop function (Cloud Functions Gen2 uses Cloud Run)
resource "google_cloud_run_service_iam_member" "stop_invoker" {
  count = var.enable_scheduling ? 1 : 0

  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.stop_instance[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# ==============================================================================
# CLOUD SCHEDULER JOBS
# ==============================================================================

# Job to start instance (default: 7am Mon-Fri)
resource "google_cloud_scheduler_job" "start_instance" {
  count = var.enable_scheduling ? 1 : 0

  name        = "${var.resource_prefix}-start-job"
  description = var.start_description
  schedule    = var.start_schedule
  time_zone   = var.schedule_timezone
  region      = var.scheduler_region
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.start_instance[0].service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.scheduler_sa[0].email
    }
  }

  retry_config {
    retry_count = 3
  }
}

# Job to stop instance (default: 8pm Mon-Fri)
resource "google_cloud_scheduler_job" "stop_instance" {
  count = var.enable_scheduling ? 1 : 0

  name        = "${var.resource_prefix}-stop-job"
  description = var.stop_description
  schedule    = var.stop_schedule
  time_zone   = var.schedule_timezone
  region      = var.scheduler_region
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.stop_instance[0].service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.scheduler_sa[0].email
    }
  }

  retry_config {
    retry_count = 3
  }
}
