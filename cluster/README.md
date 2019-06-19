# Terraform

Please note, this terraform build should be considered experimental!

This is a terraform build to deploy the Hull Stack to an Azure Kubernetes Service, and Archivematica to a standalone VM.

## Prerequisites

* Terraform
* Docker and Docker compose
* Ruby
* Azure CLI
* Azure subscription
* gem install 'azure-storage-file'

# Hull Kubernetes Stack

### Variables and data

(relative to cluster/)

* create `terraform.tfvars` (see `terraform.tfvars.template`) OR (see convention below ../../terraform_builds/myapp/terraform.tfvars)
* create file `config.json` with {} as the contents - this will be overwritten with docker auth, but must not be committed to github
* Env file at `../.env` (see `../.env.template`)
* Solr config files at ../solr/config 

### Docker images

You need Docker Images for pre-built for the following:

* hull_culture (via hyrax_leaf with .env)
* hull_synchronizer (with .env)
* hull-history-centre-bl7 (with .env)


Build with:

```
docker-compose build
```

### Deploy with Terraform

then (from the cluster directory):

```
terraform init (first time only)
terraform plan
terraform apply
```




## Automatic Stop|Start of VMs

The terraform plan creates and Automation Account and a Log Analytics Workspace. To enable automatic startup and shutdown of the underlying kubernetes VM, for example to save costs of a development or test machine, follow these steps:

In the Azure portal:

1. Navigate to Resource Group > Automation Account
2. Create a 'run as user'
3. In the left-hand menu, find Related Resources > Start/Stop VM
4. Select 'Learn more about and enable the solution' and hit Create
5. Choose the existing Automation Account, Log Analytics Workspace and Resource Group
6. In the configuration panel, enter the MC_ resource group, eg. MC_leaf-uat-rdg_leaf-uat-rdg_northeurope (this is important, otherwise the solution will shut down ALL VMs in your subscription)
7. Save

Once the deployment is complete, edit the schedules (Scheduled-StartVM and Scheduled-StopVM) as needed from within the automation account.