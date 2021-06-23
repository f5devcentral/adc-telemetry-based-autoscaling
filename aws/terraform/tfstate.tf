
terraform {
  backend "consul" {
    address     = "3.101.151.80:8500"
    scheme      = "http"
    path        = "adpm/applications/92b0/terraform/tfstate"
    gzip        = true
  }
}