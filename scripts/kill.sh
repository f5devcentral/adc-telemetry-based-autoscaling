cd ../terraform/
terraform init && terraform destroy --auto-approve
rm -rf .terraform
rm -rf .terraform.lock.hcl