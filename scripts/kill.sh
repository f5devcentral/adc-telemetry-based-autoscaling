while getopts c:b:w:t: flag
do
    case "${flag}" in
        c) cloud=${OPTARG};;
    esac
done 

cd ../$cloud/terraform/

touch tfstate.tf && rm tfstate.tf && terraform init -force-copy && terraform destroy --auto-approve
rm -rf .terraform
rm -rf .terraform.lock.hcl