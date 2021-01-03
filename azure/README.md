<img src="../images/azurelaw.png" alt="Italian Trulli">

## Deployment Overview and Prerequisites
The 'aws' Terraform project deploys a single-tiered sample application onto the AWS platform.  The appication is designed to provde telemetry data to a preconfigured analytics provider.  Sample alert configurations and TS configuration examples are included for both Elastic's ELK stack and Azure Log Analytics.  Alert configuration steps, (with relevant screenshorts are available in the 'docs' folder.  The 

* F5 BIG-IP ADC (deployed into VMSS - Standard_DS4_v2), (default = 2, min = 1, max = 5)
* Backend Workload - (NGINX deployed into VMSS - Standard_DS4_v2), (default = 2, min = 1, max = 5)
* Consul server (Ubuntu VM - Standard DS1 v2)
* Alert Forwarding (Ubuntu VM - Standard_DS1_v2)

### Variables 
* "sp_subscription_id" {default = ""}    -  Azure Subscription ID
* "sp_client_id" {default = ""}          -  Azure Client/App ID
* "sp_client_secret" {default = ""}      -  Azure Secret
* "sp_tenant_id" {default = ""}          -  Azure Tenant ID
* "prefix" {default = ""}                            -  Prefix to be appended to all Azure created resources
* "uname" {default = ""}        -  Backend server username
* "upassword" {default = ""}   -  Backend server password
* "location" {default = "westus"}        -  Azure region
* "tls_cert" {default = ""}           -  base64 encoded certiificate
* "tls_key" {default = ""}           -  base64 encoded key

#### Telemetry Variables
If using Azure Log Analytics:
* wrkspaceID = {default = ""}          - Azure Log Analytics workspace ID
* passPhrase = {default = ""}          - Azure Log Analytics passphrase

If using Elastic ELK stack, (telemtry streaming via logstash)

* logStashIP {default = ""}          - Logstash listening IP
* logStashPort {default = ""}        - Logstash listening Port

## Prerequisites
* Supported third party analytics system must be available for telemetry data ingestion/monitoring/alerting.  The 'docs' folder includes basic steps for configuring relevant alerts and actions for:
  * Azure Log Analytics
  * Elastic ELK Stack
  
* Terraform Environment
  
## Deployment Steps
1. Clone Repository - git clone https://github.com/f5devcentral/adc_perfomance_monitoring.git to a new GitHub repository Since the ADPM system utilizes GitHub Actions for automation, (at a minium, the '.github/workflows' folder must hosted in a Github repository.
2. Navigate to desired Azure subfolder.
3. Modify 'variables.tf' file and provide values for above listed variables.  Alternatively, you can utilize a terraform.tfvars file.
4. Copy the contents of either 'tsAzureLog.json' or 'tsELK.json' to 'ts.json'; depending upon which analytics provider utilized.
5. Deploy Terraform project.
6. Once Terraform has completed, use provided output variables to access the AlertForwarder server -  (Ex: ssh ubuntu@53.24.231.12) with the password noted above in the variable.tf file.
7. To start the AlertForwarding service, you will need to provide a Personal Access Token for the repository where the GitHub actions are deployed.
8. Start AlertForwarding service -  (Ex: nodejs alertForwarder.js asdfasdfadasasdfasdfasfaswreddsw).
9. Configure Appropriate Alerts via vendor UI.



