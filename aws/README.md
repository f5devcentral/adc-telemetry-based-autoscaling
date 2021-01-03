<img src="../images/awselk.png" alt="Italian Trulli">

## Deployment Overview and Prerequisites
The 'aws' Terraform project deploys a single-tiered sample application onto the AWS platform.  The appication is designed to provde telemetry data to a preconfigured analytics provider.  Sample alert configurations and TS configuration examples are included for both Elastic's ELK stack and Azure Log Analytics.  Alert configuration steps, (with relevant screenshorts are available in the 'docs' folder.  The 

* F5 BIG-IP ADC (deployed into scale group - m5.xlarge), (default = 2, min = 1, max = 5)
* Backend Workload - (NGINX deployed into scale group - t2.micro), (default = 2, min = 1, max = 5)
* Consul server (Ubuntu VM - m5.large)
* Alert Forwarding (Ubuntu VM - t2.micro)

### Variables 
* "prefix" {default = ""}                         -  Prefix to be appended to all Azure created resources
* "tls_cert" {default = ""}           -  base64 encoded certiificate
* "tls_key" {default = ""}           -  base64 encoded key
* "region"   {default = "us-west-1"}  _  AWS deployment region

#### Telemetry Variables
If using Azure Log Analytics:
* wrkspaceID = <Azure Log Analytics workspace ID>
* passPhrase = <Azure Log Analytics passphrase>

If using Elastic ELK stack, (telemtry streaming via logstash)

* logStashIP {default = ""}          - Logstash listening IP
* logStashPort {default = ""}        - Logstash listening Port

## Prerequisites
* To fully utilize the ADPM environment, a supported third party analytics system must be available for telemetry data ingestion/monitoring/alerting.  The 'docs' folder includes basic steps for configuring relevant alerts and actions for:
  * Azure Log Analytics
  * Elastic ELK Stack
* Terraform Environment
  
## Deployment Steps
1. Clone Repository - git clone https://github.com/f5devcentral/adc_perfomance_monitoring.git
2. Navigate to desired subfolder - (aws or Azure)
3. Modify 'variables.tf' file and provide values for above listed variables.  Alternatively, you can utilize a terraform.tfvars file.
4. 



