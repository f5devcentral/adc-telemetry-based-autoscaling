
terraform {
  backend "consul" {
    address     = "20.85.210.61:8500"
    scheme      = "http"
    path        = "adpm/applications/a0c4/terraform/tfstate"
    gzip        = true
  }
}