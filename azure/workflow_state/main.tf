data "template_file" "backend_file" {
  template = file("../workflow_terraform/backend.tpl")
  vars = {
    app_id  = var.app_id
    bigip_count = var.bigip_count
    workload_count   = var.workload_count
    consul_ip   = var.consul_ip
  }
}

resource "local_file" "backend" {
  content  = data.template_file.backend_file.rendered
  filename = "../workflow_terraform/backend.tf"
}