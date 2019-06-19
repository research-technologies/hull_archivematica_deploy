output "kube_config" {
  value = "${module.azure_kubernetes.kube_config}"
}

output "host" {
  value = "${module.azure_kubernetes.host}"
}

