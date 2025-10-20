# ==============================================================================
# SCHEDULER MODULE - VARIABLES
#
# Cost optimization module to automatically start/stop VPN instance
# based on business hours schedule.
# ==============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Scheduler and Functions"
  type        = string
}

variable "zone" {
  description = "GCP zone where the VM instance is located"
  type        = string
}

variable "instance_name" {
  description = "Name of the VM instance to schedule"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for scheduler resources"
  type        = string
  default     = "vpn-scheduler"
}

variable "scheduler_region" {
  description = "GCP region for Cloud Scheduler jobs. Can differ from 'var.region' (VM region). Cloud Scheduler has limited region support. See https://cloud.google.com/scheduler/docs/locations for valid regions."
  type        = string
  default     = "europe-west1"
  # IMPORTANT: This region is INDEPENDENT from the VM region (var.region).
  # Cloud Scheduler is a managed service with its own available regions.
  # Example valid regions: us-central1, europe-west1, asia-northeast1, etc.
  # If your project doesn't support the default region, change this value.
}

# ==============================================================================
# SCHEDULE CONFIGURATION
# ==============================================================================

variable "enable_scheduling" {
  description = "Enable automatic start/stop scheduling for cost optimization"
  type        = bool
  default     = true
}

variable "schedule_timezone" {
  description = "Timezone for the schedule (IANA Time Zone format, e.g., 'Europe/Madrid')"
  type        = string
  default     = "Europe/Madrid"
}

variable "start_schedule" {
  description = "Cron expression for instance start time (default: 7am Mon-Fri)"
  type        = string
  default     = "0 7 * * 1-5"
  validation {
    condition     = can(regex("^[0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+$", var.start_schedule))
    error_message = "Start schedule must be a valid cron expression (e.g., '0 7 * * 1-5')."
  }
}

variable "stop_schedule" {
  description = "Cron expression for instance stop time (default: 8pm Mon-Fri)"
  type        = string
  default     = "0 20 * * 1-5"
  validation {
    condition     = can(regex("^[0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+ [0-9*/,-]+$", var.stop_schedule))
    error_message = "Stop schedule must be a valid cron expression (e.g., '0 20 * * 1-5')."
  }
}

variable "start_description" {
  description = "Description for the start schedule job"
  type        = string
  default     = "Start VPN instance for business hours"
}

variable "stop_description" {
  description = "Description for the stop schedule job"
  type        = string
  default     = "Stop VPN instance after business hours"
}

# ==============================================================================
# CLOUD FUNCTION CONFIGURATION
# ==============================================================================

variable "function_runtime" {
  description = "Runtime for Cloud Functions"
  type        = string
  default     = "python311"
}

variable "function_timeout" {
  description = "Timeout for Cloud Functions in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.function_timeout >= 30 && var.function_timeout <= 540
    error_message = "Function timeout must be between 30 and 540 seconds."
  }
}

variable "function_memory" {
  description = "Memory allocation for Cloud Functions (MB)"
  type        = string
  default     = "256M"
}

# ==============================================================================
# LABELS
# ==============================================================================

variable "common_labels" {
  description = "Common labels to apply to scheduler resources"
  type        = map(string)
  default = {
    module    = "scheduler"
    purpose   = "cost-optimization"
    automated = "true"
  }
}

variable "bucket_kms_key" {
  description = "Customer-managed encryption key self link for function source bucket (optional)"
  type        = string
  default     = ""
}
