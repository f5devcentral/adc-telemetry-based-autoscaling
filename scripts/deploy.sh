while getopts c:b:w:t: flag
do
    case "${flag}" in
        c) cloud=${OPTARG};;
        b) bigip_count=${OPTARG};;
        w) workload_count=${OPTARG};;
        t) github_token=${OPTARG};;
    esac
done        

cd ../$cloud/terraform/

terraform init && terraform plan && terraform apply --auto-approve 
sleep 10s
terraform init -force-copy && terraform plan && terraform apply --auto-approve