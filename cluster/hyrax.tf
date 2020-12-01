# Hyrax

# Create the Build Script
# Set do_build to 'true' to build new images - this will take c. 30 mins
#   @todo build needs to delay hyrax and sidekiq pod creation, hence it being false
data "template_file" "build_script" {
  template = "${file("${path.cwd}/docker_build.tpl")}"
  vars = {
    do_build = false
    # we can use the same image for both web and worker
    # images = "hyrax_leaf_workers,hyrax_leaf_web"
    images = "hyrax_leaf_web"
  }
}

resource "local_file" "build" {
  content = "${data.template_file.build_script.rendered}"
  filename = "docker_build.rb"
  
  # Build (if do_build is set to true), tag and push the docker images
  # @todo ensure this completes before the containers pushed / deployed
  provisioner "local-exec" "build" {
    command = "ruby docker_build.rb"
  }
  
  provisioner "local-exec" "build" {
    command = "docker tag hyrax_leaf_web ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hyrax/hyrax_leaf_web"
  }
  
  provisioner "local-exec" "build" {
    command = "docker tag hull-history-centre-bl7_web ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hhc/hull-history-centre-bl7_web"
  }
  
  provisioner "local-exec" "build" {
    command = "docker tag hull_synchronizer_web ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hullsync/hull_synchronizer_web"
  }
  
  provisioner "local-exec" "build" {
    command = "az acr login --name ${module.azure_kubernetes.azure_container_registry_name}"
  }
  
  provisioner "local-exec" "build" {
    command = "docker push ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hyrax/hyrax_leaf_web"
  }
  
  provisioner "local-exec" "build" {
    command = "docker push ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hhc/hull-history-centre-bl7_web"
  }
  
  provisioner "local-exec" "build" {
    command = "docker push ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hullsync/hull_synchronizer_web"
  }
  
}

module "kubernetes_hyrax" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_two_ports_two_mounts.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hyrax/hyrax_leaf_web:latest"
  app_name = "hyrax"
  primary_mount_path = "/data"
  pvc_claim_name = "${module.kubernetes_pvc_hyrax.pvc_claim_name}"

  secondary_mount_path = "/app/shared"
  secondary_sub_path = "shared"

  # replicas = 1
  primary_port = 80
  secondary_port = 443

  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  command = ["/bin/bash","-ce", "/bin/docker-entrypoint-web.sh"]
  # Creates a dependency on fcrepo, solr and redis
  resource_version = ["${module.kubernetes_fcrepo.service_resource_version}","${module.kubernetes_fcrepo.deployment_resource_version}","${module.kubernetes_solr.deployment_resource_version}","${module.kubernetes_solr.service_resource_version}",  "${module.kubernetes_redis.deployment_resource_version}","${module.kubernetes_redis.service_resource_version}"]
  load_balancer_source_ranges = "${var.user_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_hyrax.public_ip}"
}

# A Record

module "terraform_azure_dns_arecord_hyrax" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_dns_arecord.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  
  zone_name = "${var.zone_name}"
  zone_resource_group = "${var.zone_resource_group}"
  record = "${module.terraform_azure_public_ip_hyrax.public_ip}"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

# Public IP
module "terraform_azure_public_ip_hyrax" {
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
  service_name = "hyrax"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

# Sidekiq

module "kubernetes_sidekiq" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_simple_two_mounts.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/hyrax/hyrax_leaf_web:latest"
  app_name = "sidekiq"
  primary_mount_path = "/data"
  pvc_claim_name = "${module.kubernetes_pvc_hyrax.pvc_claim_name}"

  secondary_volume_name = "sidekiq"
  secondary_mount_path = "/app/shared"
  secondary_sub_path = "shared"

  port = "3001"

  # replicas = 0
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  command = ["/bin/bash","-ce", "/bin/docker-entrypoint-worker.sh"]
  # Creates a dependency on fcrepo, solr and redis
  resource_version = ["${module.kubernetes_fcrepo.service_resource_version}","${module.kubernetes_fcrepo.deployment_resource_version}","${module.kubernetes_solr.deployment_resource_version}","${module.kubernetes_solr.service_resource_version}",  "${module.kubernetes_redis.deployment_resource_version}","${module.kubernetes_redis.service_resource_version}"]
  service_type = "ClusterIP"
}

module "kubernetes_pvc_hyrax" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "hyraxsidekiq"
  mount_size = "200G"

}
