# fcrepo
module "kubernetes_fcrepo" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  docker_image = "ualbertalib/docker-fcrepo4" # or nulib/fcrepo4"
  app_name = "fcrepo"
  primary_mount_path = "/data"
  secondary_mount_path = "/fcrepo" # currently unused, but could be
  secondary_sub_path = "fcrepo_config"
  pvc_claim_name = "${module.kubernetes_pvc_fcrepo.pvc_claim_name}"
  port = 8080
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  load_balancer_source_ranges = "${var.developer_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_fcrepo.public_ip}"

  # Creates a dependency on postgres
  resource_version = ["${module.kubernetes_postgres.service_resource_version}","${module.kubernetes_postgres.deployment_resource_version}"]
}

# Public IP
module "terraform_azure_public_ip_fcrepo" {
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
  service_name = "fcrepo"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

module "kubernetes_pvc_fcrepo" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "fcrepo"

}