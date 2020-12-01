# Hull Synchronizer

module "kubernetes_hullsynchronizer" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_two_ports_two_mounts.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hullsync/hull_synchronizer_web:latest"
  app_name = "hullsynchronizer"
  primary_mount_path = "/data"
  pvc_claim_name = "${module.kubernetes_pvc_hull_synchronizer.pvc_claim_name}"

  secondary_mount_path = "/app/shared"
  secondary_sub_path = "shared"

  # replicas = 1
  primary_port = 80
  secondary_port = 443

  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  command = ["/bin/bash","-ce", "/bin/docker-entrypoint.sh"]
  # Creates a dependency on fcrepo, solr and redis
  resource_version = ["${module.kubernetes_fcrepo.service_resource_version}","${module.kubernetes_fcrepo.deployment_resource_version}","${module.kubernetes_solr.deployment_resource_version}","${module.kubernetes_solr.service_resource_version}",  "${module.kubernetes_redis.deployment_resource_version}","${module.kubernetes_redis.service_resource_version}"]
  load_balancer_source_ranges = "${var.user_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_hullsync.public_ip}"
}

# A Record

module "terraform_azure_dns_arecord_hullsync" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_dns_arecord.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "hullsync"
  
  zone_name = "${var.zone_name}"
  zone_resource_group = "${var.zone_resource_group}"
  record = "${module.terraform_azure_public_ip_hullsync.public_ip}"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

# Public IP
module "terraform_azure_public_ip_hullsync" {
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
  service_name = "hullsynchronizer"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

module "kubernetes_hullsync_sidekiq" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_simple_two_mounts.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hullsync/hull_synchronizer_web:latest"

  app_name = "hullsyncsidekiq"
  primary_mount_path = "/data"
  pvc_claim_name = "${module.kubernetes_pvc_hull_synchronizer.pvc_claim_name}"

  secondary_volume_name = "hullsyncsidekiq"
  secondary_mount_path = "/app/shared"
  secondary_sub_path = "shared"

  port = "3001"

  # replicas = 0
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  command = ["/bin/bash","-ce", "bundle exec sidekiq"]
  # Creates a dependency on redis
  resource_version = ["${module.kubernetes_redis.deployment_resource_version}","${module.kubernetes_redis.service_resource_version}"]
  service_type = "ClusterIP"
}

module "kubernetes_pvc_hull_synchronizer" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "hullsynchronizer"
  mount_size = "300G"

}
