while getopts b:w:t: flag
do
    case "${flag}" in
        b) bigip_count=${OPTARG};;
        w) workload_count=${OPTARG};;
        t) github_token=${OPTARG};;
    esac
done
cd ../azure/terraform/
terraform init && terraform plan -var="bigip_count=$bigip_count" -var="workload_count=$workload_count" -var="github_token=$github_token" && terraform apply --auto-approve -var="bigip_count=$bigip_count" -var="workload_count=$workload_count" -var="github_token=$github_token"
sleep 10s
terraform init -force-copy && terraform plan -var="bigip_count=$bigip_count" -var="workload_count=$workload_count" -var="github_token=$github_token" && terraform apply --auto-approve -var="bigip_count=$bigip_count" -var="workload_count=$workload_count" -var="github_token=$github_token"
