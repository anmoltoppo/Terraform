# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "The location that the resources will run in (e.g. East US)"
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources for consul will run in"
}

variable "storage_account_name" {
  description = "The name of the storage account that will be used for images"
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the cluster into"
}

variable "cluster_name" {
  description = "The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module."
}

variable "storage_container_name" {
  description = "The name of the Azure Storage Container where secrets will be kept."
}

variable "image_id" {
  description = "The URL of the Image to run in this cluster. Should be an image that had Consul installed and configured by the install-consul module."
}

variable "instance_size" {
  description = "The size of Azure Instances to run for each node in the cluster (e.g. Standard_A0)."
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "custom_data" {
  description = "A Custom Data script to execute while the server is booting. We remmend passing in a bash script that executes the run-consul script, which should have been installed in the Consul Image by the install-consul module."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_tier" {
  description = "Specifies the tier of virtual machines in a scale set. Possible values, standard or basic."
  default = "standard"
}

variable "consul_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default = "consul"
}

variable "vault_computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default = "vault"
}

variable "consul_admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default = "consuladmin"
}

variable "vault_admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default = "vaultadmin"
}

variable "instance_root_volume_size" {
  description = "Specifies the size of the instance root volume in GB. Default 40GB"
  default     = 40
}

variable "cluster_size" {
  description = "The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5."
  default     = 3
}

variable "cluster_tag_key" {
  description = "Add a tag with this key and the value var.cluster_tag_value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "consul-servers"
}

variable "cluster_tag_value" {
  description = "Add a tag with key var.clsuter_tag_key and this value to each Instance in the ASG. This can be used to automatically find other Consul nodes and form a cluster."
  default     = "auto-join"
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Azure Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "associate_public_ip_address_load_balancer" {
  description = "If set to true, create a public IP address with back end pool to allow SSH publically to the instances."
  default     = false
}

variable "root_volume_type" {
  description = "The type of volume. Must be one of: standard, gp2, or io1."
  default     = "standard"
}

variable "root_volume_size" {
  description = "The size, in GB, of the root EBS volume."
  default     = 50
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination."
  default     = true
}

variable "api_port" {
  description = "The port to use for Vault API calls"
  default     = 8200
}

terraform {
  required_version = ">= 0.10.0"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE STORAGE BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "vault" {
  name                  = "${var.storage_container_name}"
  resource_group_name   = "${var.resource_group_name}"
  storage_account_name  = "${var.storage_account_name}"
  container_access_type = "private"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A LOAD BALANCER
#---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "vault_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label = "${var.cluster_name}"
}

resource "azurerm_lb" "vault_access" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}_access"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.vault_access.id}"
  }
}

resource "azurerm_lb_nat_pool" "vault_lbnatpool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "ssh"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  protocol = "Tcp"
  frontend_port_start = 2200
  frontend_port_end = 2299
  backend_port = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "vault_probe" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  name                = "vault-running-probe"
  port                = "${var.api_port}"
}

resource "azurerm_lb_backend_address_pool" "vault_bepool" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  name = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "vault_api_port" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  name = "vault-api"
  loadbalancer_id = "${azurerm_lb.vault_access.id}"
  protocol = "Tcp"
  frontend_port = "${var.api_port}"
  backend_port = "${var.api_port}"
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.vault_bepool.id}"
  probe_id = "${azurerm_lb_probe.vault_probe.id}"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN VAULT (WITHOUT LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "vault" {
  count = "${var.associate_public_ip_address_load_balancer ? 0 : 1}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.vault_computer_name_prefix}"
    admin_username = "${var.vault_admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.vault_admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "VaultNetworkProfile"
    primary = true

    ip_configuration {
      name = "VaultIPConfiguration"
      subnet_id = "${var.subnet_id}"
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A VIRTUAL MACHINE SCALE SET TO RUN VAULT (WITH LOAD BALANCER)
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine_scale_set" "vault_with_load_balancer" {
  count = "${var.associate_public_ip_address_load_balancer ? 1 : 0}"
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name = "${var.instance_size}"
    tier = "${var.instance_tier}"
    capacity = "${var.cluster_size}"
  }

  os_profile {
    computer_name_prefix = "${var.vault_computer_name_prefix}"
    admin_username = "${var.vault_admin_user_name}"

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path = "/home/${var.vault_admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  network_profile {
    name = "VaultNetworkProfile"
    primary = true

    ip_configuration {
      name = "VaultIPConfiguration"
      subnet_id = "${var.subnet_id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.vault_bepool.id}"]
      load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_pool.vault_lbnatpool.*.id, count.index)}"]
    }
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name = ""
    caching = "ReadWrite"
    create_option = "FromImage"
    os_type = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    scaleSetName = "${var.cluster_name}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "vault" {
  name = "${var.cluster_name}"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_network_security_rule" "ssh" {
  count = "${length(var.allowed_ssh_cidr_blocks)}"

  access = "Allow"
  destination_address_prefix = "*"
  destination_port_range = "22"
  direction = "Inbound"
  name = "SSH${count.index}"
  network_security_group_name = "${azurerm_network_security_group.vault.name}"
  priority = "${100 + count.index}"
  protocol = "Tcp"
  resource_group_name = "${var.resource_group_name}"
  source_address_prefix = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range = "1024-65535"
}

output "scale_set_name" {
  value = "${var.cluster_name}"
}

output "admin_user_name" {
  value = "${var.vault_admin_user_name}"
}

output "cluster_size" {
  value = "${var.cluster_size}"
}

output "storage_containter_id" {
  value = "${azurerm_storage_container.vault.id}"
}

output "load_balancer_ip_address" {
  value = "${azurerm_public_ip.vault_access.ip_address}"
}