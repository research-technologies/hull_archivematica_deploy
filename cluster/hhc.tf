# Hull Synchronizer

# Create the Build Script
# Set do_build to 'true' to build new images - this will take c. 30 mins
module "kubernetes_hhc" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hhc/hull-history-centre-bl7_web:latest"
  app_name = "hhc"
  primary_mount_path = "/data"
  secondary_mount_path = "/app/shared"
  secondary_sub_path = "shared"
  pvc_claim_name = "${module.kubernetes_pvc_hyrax.pvc_claim_name}"
  # replicas = 1
  port = 80
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  command = ["/bin/bash","-ce", "/bin/docker-entrypoint.sh"]
  # Creates a dependency on fcrepo, solr and redis
  resource_version = ["${module.kubernetes_fcrepo.service_resource_version}","${module.kubernetes_fcrepo.deployment_resource_version}","${module.kubernetes_solr.deployment_resource_version}","${module.kubernetes_solr.service_resource_version}",  "${module.kubernetes_redis.deployment_resource_version}","${module.kubernetes_redis.service_resource_version}"]
  load_balancer_source_ranges = "${var.user_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_hhc.public_ip}"
}

# A Record

module "terraform_azure_dns_arecord_hhc" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_dns_arecord.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "hullhistorycentre"
  
  zone_name = "${var.zone_name}"
  zone_resource_group = "${var.zone_resource_group}"
  record = "${module.terraform_azure_public_ip_hhc.public_ip}"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

# Public IP
module "terraform_azure_public_ip_hhc" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_public_ip.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "hhc"
  
  location = "${var.location}"
  resource_group = "${module.azure_kubernetes.azure_cluster_node_resource_group}"
  service_name = "hhc"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

module "kubernetes_pvc_hhc" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "hhc"

}