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

variable tls_cert {
  type    = string
  default = "-----BEGIN CERTIFICATE-----\nMIIFWjCCBEKgAwIBAgITfQAAAB0gY6x6LLG8KwAAAAAAHTANBgkqhkiG9w0BAQUF\nADBOMRMwEQYKCZImiZPyLGQBGRYDY29tMRowGAYKCZImiZPyLGQBGRYKYXNlcnJh\nY29ycDEbMBkGA1UEAxMSYXNlcnJhY29ycC1EQy1DQS0xMB4XDTIwMDIxNTIyMTIw\nMloXDTIyMDIxNDIyMTIwMlowHzEdMBsGA1UEAxMUbXlhcHAuYXNlcnJhY29ycC5j\nb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTGBNbVYLJiIDfL0FQ\nMi/mFzcLeQhP11c4YdxjMBPJKSBWKnXuxywcOJHJ6A2rpGKhAApSsVc6j6sXfCty\nbszbNgvx7KdV8c2S02ILNqlJwTOXRkQhN0srlATYdF/i6T1Y1fpkjBiZMC7A8fRf\nQNwT8DgberiuN4YvfsNGbQej+a1dOVQAGaBn15xwXe8Xfw9iLRangb8n4yAz4qS2\nIJig2UYzSc3P6k1ulZ6I1Yo/xOj7zar3R/09DZ6ikGBvy3TrSfYpRX8pXFgFsJOl\nDeYwzAKlKY4MnapgwszIFMmxveK/d3K+l3Kn0791VdBklrrlycV7itGXrqNYdHLg\nC3dPAgMBAAGjggJeMIICWjA7BgkrBgEEAYI3FQcELjAsBiQrBgEEAYI3FQiBg9Bp\ng5vnB4b5lxighjeD8YE0eYL+ujyChWkCAWQCAQMwEwYDVR0lBAwwCgYIKwYBBQUH\nAwEwDgYDVR0PAQH/BAQDAgWgMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwEw\nHQYDVR0OBBYEFMXq6/mUs8bg5TUoL3uXPUyyAFyXMB8GA1UdIwQYMBaAFBEzMhC4\nl6myjmO0WBY2s0tLj1fQMIHOBgNVHR8EgcYwgcMwgcCggb2ggbqGgbdsZGFwOi8v\nL0NOPWFzZXJyYWNvcnAtREMtQ0EtMSxDTj1kYyxDTj1DRFAsQ049UHVibGljJTIw\nS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1h\nc2VycmFjb3JwLERDPWNvbT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/\nb2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgccGCCsGAQUFBwEBBIG6\nMIG3MIG0BggrBgEFBQcwAoaBp2xkYXA6Ly8vQ049YXNlcnJhY29ycC1EQy1DQS0x\nLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxD\nTj1Db25maWd1cmF0aW9uLERDPWFzZXJyYWNvcnAsREM9Y29tP2NBQ2VydGlmaWNh\ndGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MA0GCSqG\nSIb3DQEBBQUAA4IBAQC8xoaBDhn0BGqQ73ROjlvI+5yJs3UUws2D7KCtpzNt2Ksm\ngm52umZoIzofPRXg/RVkt+Ig7Y9+ixaEyAxMFtpDyap1bTNjWsw99LoUZvMo7B9q\nrgOS55h5OeLwc1PM3n43I9H2C3uQ1hYflD3ovzvzrywejCHlHlReovZkYCcrDCa+\nytw7Hob0P1vkXsPtpmk61A7PCLw6DghhczT1f4nAK147FuRl55jz38JFOtqKVlfU\nNH4EaSxciHO2evWDHUddzeAwxHLg77UKPH+MSPXd7jGZx3xqQEtpjMqq5WM09YsL\n1mwOJpk1Xarkb0WB0J10YXqKs6tSxyrfX/FL5MZA\n-----END CERTIFICATE-----"
}			
 
 variable tls_key {
  type    = string
  default = "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDTGBNbVYLJiIDf\nL0FQMi/mFzcLeQhP11c4YdxjMBPJKSBWKnXuxywcOJHJ6A2rpGKhAApSsVc6j6sX\nfCtybszbNgvx7KdV8c2S02ILNqlJwTOXRkQhN0srlATYdF/i6T1Y1fpkjBiZMC7A\n8fRfQNwT8DgberiuN4YvfsNGbQej+a1dOVQAGaBn15xwXe8Xfw9iLRangb8n4yAz\n4qS2IJig2UYzSc3P6k1ulZ6I1Yo/xOj7zar3R/09DZ6ikGBvy3TrSfYpRX8pXFgF\nsJOlDeYwzAKlKY4MnapgwszIFMmxveK/d3K+l3Kn0791VdBklrrlycV7itGXrqNY\ndHLgC3dPAgMBAAECggEADudNPo6L/FSR3LAGaXYRoaoT7dBuwMxQUR+/opUbYIFx\n0gOPbftL5vYrfNjQVkT13a4WDH6OzQilqLPQkXS3K+bl8v+lVNEMlYgtDOOgEh/8\n13pThxDTUtFRgkK9HlUfSq1Yz06A0hfvxRmQCkWXBCVaoL4KWep7o9DMUqWR+4ad\nXlvzvG2W3fvNE3+ewwf0tR/OYTQOZvkRfm0Ws1s0W85wr6Ec87psbLPPO2yecFcq\n3fJjcZmbaWWG5Thh9479W3rhC3I6rJN+YLgyXoumml5wmmjf8CxocUL3uPt+32u5\nE4OZTLdAIF0+KxH3hYbw3D6DB/LnAZVB+jxmOC4j2QKBgQDm5JVzld5KYUlIt566\nsyQ95JMyw0Oqp1U7WMwI8+RMYnO4NPo6Dzej9LMsVAQFmg5DncElSf3PLC9PfsVe\nCK6FiXPScy/9cAqchJVI3f7CgJiYvrFwoiieVJFYSgh52aWxL/KHnEe4UWk50qmS\n/hCyPdSCHJVw1oh5dIO/QGG+YwKBgQDqDFi8mNrUI/QD+m/2HNT+6PaXUWEfyY94\n/swvn9O+qQYWbU8MCxeucthTJ5p5lYY5FdUeKPGZn0jahgoEV63XnuemNe43tOJA\nDpo1UyWmQoodAOOm9QiEEjOAxx+hEcSfJrEUgGSYVR+GHbap+xuB0BrtCN9qWsdb\nU2d25b4xJQKBgQCV4SAardhkVA6sQ3WoIA2Ql8Xtl89fAcxT/+pCjX9PDkGr+8fK\n1IH7ziZYyhjqQfysa8UrHYLCbx4u7k3UIrKXQIiMvfUTAR4CSBZX/LMZMzzbOj4Y\nrUrMrHzE4Rnrbxsdj9BRs2LjBQXXYSZuornX2kcORtvDKZ/hp362MWbBnQKBgQCo\nSZZojXQTQ4LKdYGZsmOIotPkO9SdOZ3a/0KsH7zuA7Tn3VMQMs2lVtiq+ff94oCv\nfT5PQFtv/XMyBV0ggDb0qkKgZXjTP1HLg3RoUU/p+0A52JDYVKn55Oh5eTQJ6a+6\nS+TZ+/PZAKP5GFZmZLMDpTInK9ERNRLRXOgxOsKFrQKBgQDH6PfQTuvubwL+CYbb\nCI1AtWOGEGcuLIbtlbh5e4/1FxtdG2pgV2wBJxIwNhn8U7yMHj9B/MB39OAt6Vlc\nZU0Dah41RMi4dPGAi/iuTQklfRLjROSVmhb/lS9xDRxzHcm0u0YBuU0Q+MC3aw7O\njXWs11QDs5AR93mLB0AZdRjGLA==\n-----END PRIVATE KEY-----"
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
