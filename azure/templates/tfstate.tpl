
terraform {
  backend "consul" {
    address     = "${consul_ip}:8500"
    scheme      = "http"
    path        = "adpm/applications/${app_id}/terraform/tfstate"
    gzip        = true
  }
}