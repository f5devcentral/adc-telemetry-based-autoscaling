terraform {
  backend "consul" {
    address     = "${consul_ip}"
    scheme      = "http"
    path        = "adpm/applications/${app_id}/terraform/tfstate"
    gzip        = true
  }
}

data "terraform_remote_state" "state" {
  backend = "consul"
  config = {
    address     = "${consul_ip}"
    path = "adpm/applications/${app_id}/terraform/tfstate"
  }
}

locals{
    app_id  = "${app_id}"
    bigip_count = ${bigip_count}
    workload_count   = ${workload_count}
}
