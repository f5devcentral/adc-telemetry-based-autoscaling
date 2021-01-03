## Deployment Overview and Prerequisites
The 'aws' Terraform project deploys a single-tiered sample application onto the AWS platform.  The appication is designed to provde telemetry data to a preconfigured analytics provider.  Sample alert configurations and TS configuration examples are included for both Elastic's ELK stack and Azure Log Analytics.  Alert configuration steps, (with relevant screenshorts are available in the 'docs' folder.  The 

* F5 BIG-IP ADC (deployed into scale group), (default = 2, min = 1, max = 5)
* Backend Workload - (NGINX deployed into scale group), (default = 2, min = 1, max = 5)
* Consul server (VM)
* Alert Forwarding (VM)

<img src="../images/awselk.png" alt="Italian Trulli">


### TERRAFORM INPUTS
The following values will be required to deploy, (either entered during apply or updated via variables.tf). Additional value can be updated via the terraform.tfvars file.  A sample tfvars file isincluded for referenc.

#### Application Variables
* prefix =  <string value prepended to all created resources>  
* tls_cert = <base64 encoded certiificate string>
* tls_pswd = <base64 encoded password>

#### Telemetry Variables
* wrkspace_id = <Azure Log Analytics workspace ID>
* passphrase = <Azure Log Analytics passphrase>

