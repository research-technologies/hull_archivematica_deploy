# Copy the solr data
data "template_file" "copy_script" {
  template = "${file("${path.cwd}/copy_solr_config.tpl")}"
  vars = {
    azure_resource_group_name = "MC_${module.azure_kubernetes.azure_resource_group_name}_${module.azure_kubernetes.azure_resource_group_name}_${var.location}"
    share_name = "kubernetes-dynamic-${module.kubernetes_pvc_solr.volume_name}"
  }
}

# Transfer the solr config
resource "local_file" "create_copy_script" {
  
  content = "${data.template_file.copy_script.rendered}"
  filename = "create_copy_script.rb"

  provisioner "local-exec" "copy" {
    command = "ruby create_copy_script.rb"
  }
}

# solr
module "kubernetes_solr" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_simple_two_mounts.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "solr:7-alpine"

  app_name = "solr"
  primary_mount_path = "/opt/solr/server/solr/mycores"
  pvc_claim_name = "${module.kubernetes_pvc_solr.pvc_claim_name}"

  # Another mount to same volume 
  secondary_volume_name = "solr"
  secondary_mount_path = "/data"
  secondary_sub_path = "solr_config"

  load_balancer_source_ranges = "${var.developer_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_solr.public_ip}"
  
  port = 8983

  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  
  command = ["/bin/bash","-ce", "docker-entrypoint.sh && precreate-core $${SOLR_CORE} /data/hyrax && solr-precreate $${HHC_SOLR_CORE} /data/hhc"]

}

# Public IP
module "terraform_azure_public_ip_solr" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_public_ip.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  
  location = "${var.location}"
  resource_group = "${module.azure_kubernetes.azure_cluster_node_resource_group}"
  service_name = "solr"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}


module "kubernetes_pvc_solr" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "solr"
  mount_size = "100G"

}
