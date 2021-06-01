variable bigip_count {
  description = "Number of Bigip instances to create( From terraform 0.13, module supports count feature to spin mutliple instances )"
  type        = number
}

variable workload_count {
  description = "Number of backend application instances to create( From terraform 0.13, module supports count feature to spin mutliple instances )"
  type        = number
}

variable bigip_min {
  type    = number
  default = 1
}

variable bigip_max {
  type    = number
  default = 4
}

variable workload_min {
  type    = number
  default = 1
}

variable workload_max {
  type    = number
  default = 4
}
variable scale_interval {
  type    = number
  default = 300
}

variable ts_consumer {
  description   = "The analytics consumer connecting to   1 = splunk   2 = elk   3 = azure log analytics"
  type    = number
  default = 1
}

variable "ts_params_mapping_1" {
  description = "mapping for cross-region replication"
  default = {
    1 = var.splunkIP,
    2 = var.logStashIP,
    3 = var.law_id
  }
}

variable "ts_params_mapping_2" {
  description = "mapping for cross-region replication"
  default = {
    1 = var.splunkHEC,
    2 = "",
    3 = var.law_primarykey
  }
}

variable app_name {
  type    = string
  default = "sample_app"
}

variable consul_ip {
  type        = string
  description = "private address assigned to consul server"
  default     = "10.2.1.100"
}

variable github_token {
  type        = string
  description = "repo token required to update secrets"
}

variable github_owner {
  type        = string
  description = "repo owner required to update secrets"
  default     = ""
}

variable repo_path {
  type        = string
  description = "repo path for github actions"
  default     = "/repos/f5devcentral/adc-telemetry-based-autoscaling/dispatches"
}

variable prefix {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "application"
}

variable location {default = "eastus"}

variable cidr {
  description = "Azure VPC CIDR"
  type        = string
  default     = "10.2.0.0/16"
}

variable upassword {default = "F5demonet!"}

variable availabilityZones {
  description = "If you want the VM placed in an Azure Availability Zone, and the Azure region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use."
  type        = list
  default     = [2]
}

variable AllowedIPs {
}

# TAGS
variable "purpose" { default = "public" }
variable "environment" { default = "f5env" } #ex. dev/staging/prod
variable "owner" { default = "f5owner" }
variable "group" { default = "f5group" }
variable "costcenter" { default = "f5costcenter" }
variable "application" { default = "f5app" }
