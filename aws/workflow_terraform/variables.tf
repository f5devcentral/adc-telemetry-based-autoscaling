variable splunkIP {
  type = string
}    

variable splunkHEC {
  type = string
}     

variable logStashIP {
  type = string
}

variable law_id {
  type = string
}         

variable law_primarykey {
  type = string
}  

variable ts_consumer {
  description   = "The analytics consumer connecting to   1 = splunk   2 = elk   3 = azure log analytics"
  type    = number
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
      
variable app_name {
  type    = string
  default = "sample_app"
}

variable consul_ip {
  type        = string
  description = "private address assigned to consul server"
  default     = "10.0.1.225"
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

variable ubuntu_ami_search_name {
  description = "Ubuntu AMI name to search for"
  type        = string
  default     = "*ubuntu-bionic-18.04-amd64-server-*"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
  default     = "tf-demo-key"
}

variable cidr {
  description = "aws VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable region {}

variable availabilityZones {
  description = "If you want the VM placed in an AWS Availability Zone, and the AWS region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use."
  type        = list
  default     = ["us-east-1a", "us-east-1b"]
}

variable AllowedIPs {
  default = ["0.0.0.0/0"]
}

# TAGS
variable "purpose" { default = "public" }
variable "environment" { default = "f5env" } #ex. dev/staging/prod
variable "owner" { default = "f5owner" }
variable "group" { default = "f5group" }
variable "costcenter" { default = "f5costcenter" }
variable "application" { default = "f5app" }
