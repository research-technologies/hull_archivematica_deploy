# postgresql
module "kubernetes_postgres" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  docker_image = "postgres:11-alpine"
  app_name = "postgresdb"
  
  primary_mount_path = "/var/lib/postgresql/data" # DO NOT CHANGE; ENSURE PGDATA is set in .env
  secondary_mount_path = "/data" # this isn't used or needed
  secondary_sub_path = "unused"
  pvc_claim_name = "${module.kubernetes_pvc_postgresdb.pvc_claim_name}"
  # load_balancer_source_ranges = "${var.developer_access}"
  service_type = "ClusterIP"
  
  port = 5432
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"

}

module "kubernetes_pvc_postgresdb" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume= "postgresdb"
  storage_class_name = "azuredisk"

}

