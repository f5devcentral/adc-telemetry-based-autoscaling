variable "prefix" {
  default = "scs"
}


variable "location" {
  default = "eastus"
}

variable "region" {
  default = "East US"
}
# NETWORK
variable "cidr" {
  default = "10.90.0.0/16"
}

variable "subnets" {
  type = map(string)
  default = {
    "subnet1" = "10.90.1.0/24"
    "subnet2" = "10.90.2.0/24"
    "subnet3" = "10.90.3.0/24"
  }
}

# TAGS
variable "purpose" {
  default = "public"
}

variable "environment" { #ex. dev/staging/prod
  default = "f5env"
}

variable "owner" {
  default = "f5owner"
}

variable "group" {
  default = "f5group"
}

variable "costcenter" {
  default = "f5costcenter"
}

variable "application" {
  default = "f5app"
}

variable "host1_name" {
  default = "f5vm01"
}

variable "dns_server" {
  default = "8.8.8.8"
}

variable "ntp_server" {
  default = "0.us.pool.ntp.org"
}

variable "f5vm01mgmt" {
  default = "10.90.1.4"
}

variable "f5vm01ext" {
  default = "10.90.2.4"
}

variable "backend01ext" {
  default = "10.90.2.101"
}

# BIGIP Image
variable "instance_type" {
  default = "Standard_DS4_v2"
}

variable "image_name" {
  default = "f5-bigip-virtual-edition-25m-best-hourly"
}

variable "product" {
  default = "f5-big-ip-best"
}

variable "bigip_version" {
  default = "latest"
}

# BIGIP Setup
variable "license1" {
  default = ""
}

variable "libs_dir" {
  default = "/config/cloud/azure/node_modules"
}

variable "onboard_log" {
  default = "/var/log/startup-script.log"
}

# REST API Setting
variable "rest_do_uri" {
  default = "/mgmt/shared/declarative-onboarding"
}

variable "rest_as3_uri" {
  default = "/mgmt/shared/appsvcs/declare"
}

variable "rest_do_method" {
  default = "POST"
}

variable "rest_as3_method" {
  default = "POST"
}

variable "rest_vm01_do_file" {
  default = "vm01_do_data.json"
}
variable "DO_onboard_URL" {
  default = "https://github.com/garyluf5/f5tools/raw/master/f5-declarative-onboarding-1.3.0-4.noarch.rpm"
}


variable "uname" {
  default = "azureuser"
}

variable "upassword" {
  default = "Default12345"
}

variable "AS3_URL" {
  default = "https://github.com/garyluf5/f5tools/raw/master/f5-appsvcs-3.9.0-3.noarch.rpm"
}

variable "timezone" {
  default = "UTC"
}

variable "f5vm01ext_sec" {
  default = "10.90.2.11"
}
