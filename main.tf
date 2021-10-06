# Terraform Providers 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.48.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Azure Subscription
data "azurerm_subscription" "primary" {}

# Azure AD Configuration
data "azuread_client_config" "current" {}

# Existing Azure AD Group in Active Directory for AKS Admins
data "azuread_group" "aks_administrator" {
  display_name = "aks-administrator"
  security_enabled = true
  # Members of the Group 
}

# Exiting Resource Group
data "azurerm_resource_group" "primary_rg" {
  name = "primary"
}

###############################################################
## Azure Key Vault ##
###############################################################

# Exiting key Vault
data "azurerm_key_vault" "cluster_pod_keyvault" {
  name                             = "cluster-pod-keyvault"
  resource_group_name              = data.azurerm_resource_group.primary_rg.name
}

# Exiting key Vault key
data "azurerm_key_vault_key" "cluster_pod_keyvault_key" {
  name                             = "clusterkey"
  key_vault_id                     = data.azurerm_key_vault.cluster_pod_keyvault.id
}

###############################################################
## Azure Role Assignment ##
###############################################################

# # Azure Role Assignment
resource "azurerm_role_assignment" "kubelet_cluster_admin_role" {
  scope                            = data.azurerm_resource_group.primary_rg.id
  role_definition_name             = "AKS Cluster Admin"
  principal_id                     = data.azuread_group.aks_administrator.object_id
}

resource "azurerm_role_assignment" "cluster_admin_rbac_role" {
  scope                            = data.azurerm_resource_group.primary_rg.id
  role_definition_name             = "AKS Rbac Cluster admin"
  principal_id                     = data.azuread_group.aks_administrator.object_id
}

resource "azurerm_role_assignment" "cluster_contributer_rbac_role" {
  scope                            = data.azurerm_resource_group.primary_rg.id
  role_definition_name             = "cluster contributer rbac role"
  principal_id                     = data.azuread_group.aks_administrator.object_id
}

resource "azurerm_role_assignment" "acr_container_registry" {
  scope                            = data.azurerm_container_registry.acr_controller.id
  role_definition_name             = "AcrPull"
  principal_id                     = data.azurerm_user_assigned_identity.cluster_managed_identity.principal_id
}

resource "azurerm_role_assignment" "cluster_pod_keyvault" {
  scope                            = data.azurerm_key_vault.cluster_pod_keyvault.id
  role_definition_name             = "Reader"
  principal_id                     = data.azurerm_user_assigned_identity.cluster_managed_identity.principal_id
}

###############################################################
## Azure User Assigned Identity ##
###############################################################

# Create user assigned identity
resource "azurerm_user_assigned_identity" "cluster_managed_identity" {
  resource_group_name = data.azurerm_resource_group.primary_rg.name
  location            = data.azurerm_resource_group.primary_rg.location
  name                = "${azurerm_kubernetes_cluster.anmol_cluster.name}-agentpool"
}

# Existing User Assigned Identity
data "azurerm_user_assigned_identity" "cluster_managed_identity" {
  name                = "${azurerm_kubernetes_cluster.anmol_cluster.name}-agentpool"
  resource_group_name = azurerm_kubernetes_cluster.anmol_cluster.node_resource_group
}

###############################################################
## Azure Log Analytics workspace ##
###############################################################

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "logsanmol" {
  name                             = "logs-aks"
  location                         = data.azurerm_resource_group.primary_rg.location
  resource_group_name              = data.azurerm_resource_group.primary_rg.name
  retention_in_days                = 30
}

###############################################################
## Azure ACR Repository ##
###############################################################
data "azurerm_container_registry" "acr_controller" {
  name = "acrcontroller"
  resource_group_name = data.azurerm_resource_group.primary_rg
}

###############################################################
## Azure Kubernetes Services ##
###############################################################

# Datasource to get Latest Azure AKS latest Version
data "azurerm_kubernetes_service_versions" "current" {
  location = data.azurerm_resource_group.primary_rg.location
}

data "azurerm_resource_group" "node_resource_group" {
  depends_on = [
    azurerm_kubernetes_cluster.anmol_cluster]
  name = azurerm_kubernetes_cluster.anmol_cluster.node_resource_group  
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "anmol_cluster" {
  dns_prefix          = "aksclusterdns"
  location            = data.azurerm_resource_group.primary_rg.location
  name                = "anmolcluster"
  resource_group_name = data.azurerm_resource_group.primary_rg.name
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version  # orchestrator version of Kubernetes.

  default_node_pool {
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    name                 = "anmolnodepool"
    node_count           = 1
    node_labels          = {name = "AnmolApp"} 
    vm_size              = "Standard_DS2_v2"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version # version of Kubernetes to use in the node pool
  }

# Identity (System Assigned or Service Principal)
  identity {
    type = "SystemAssigned"
  }

# Tags
  tags = {
    Environment = "QA"
  }

# Add On Profiles
  addon_profile {
    azure_policy {enabled =  true}
    oms_agent {
      enabled =  true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.logsanmol.id
    }
  }

# RBAC and Azure AD Integration Block
  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed = true
      admin_group_object_ids = [data.azuread_group.aks_administrator.id]
    }
  }

# Network Profile
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "Standard"
  }
}

###############################################################
## namespace, Service Account and Cluster role and role binding ##
###############################################################

# virtual clusters are called namespace, Adding namespace (Prod/Dev/QA)
resource "kubernetes_namespace" "anmol_namespace" {
  metadata {
    name = "anmolnamespace"
  }
  depends_on = [
  azurerm_kubernetes_cluster.anmol_cluster
  ]
}

# service account provides an identity for processes that run in a Pod
resource "kubernetes_service_account" "anmol_serviceaccount" {
  metadata {
    name      = "anmolserviceaccount"
    namespace = "${kubernetes_namespace.anmol_namespace.metadata.0.name}"
  }
}

# kubernetes cluster role
resource "kubernetes_cluster_role" "all_can_list_namespaces" {
  depends_on = [azurerm_kubernetes_cluster.anmol_cluster]
  metadata {
    name = "list-namespaces"
  }

  rule {
    api_groups = ["*"]
    resources = [
      "namespaces"
    ]
    verbs = [
      "list",
    ]
  }
}

# kubernetes cluster role binding
resource "kubernetes_cluster_role_binding" "anmol_rolebinding" {
  metadata {
    name = kubernetes_service_account.anmol_serviceaccount.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.anmol_serviceaccount.metadata.0.name
    namespace = kubernetes_namespace.anmol_namespace.metadata.0.name
  }
}

###############################################################
## Azure Helm chart and aad-pod-identity ##
###############################################################

locals {

  # Kubernetes Container Storage Interface (CSI)
  azure_csi_settings = {
    linux = {
      enabled = true
      resources = {
        requests = {
          cpu    = "100m"
          memory = "100Mi"
        }
        limits = {
          cpu    = "100m"
          memory = "100Mi"
        }
      }
    }
    secrets-store-csi-driver = {
      install = true
      linux = {
        enabled = true
      }
      logLevel = {
        debug = true
      }
    }
  }

  # Kubernetes pod-managed identities
  aad_pod_identity_settings = {
    forceNameSpaced = false
    mic = {
      image = "mic"
      tag   = "1.6.1"
      resources = {
        limits = {
          cpu    = "200m"
          memory = "1024Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "512Mi"
        }
      }
    }
    nmi = {
      image = "nmi"
      tag   = "1.6.1"
      resources = {
        limits = {
          cpu    = "200m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
    }
    rbac = {
      enabled = true
    }
    installCRDs = true
  }  
}

resource "helm_release" "azure_csi" {
  name         = "csi-secrets-store-provider-azure"
  chart        = "csi-secrets-store-provider-azure"
  version      = "0.0.8"
  repository   = "https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/charts"
  namespace    = "kube-system"
  create_namespace = true
  max_history  = 4
  atomic       = true
  reuse_values = false
  timeout      = 1800
  values       = [yamlencode(local.azure_csi_settings)]
  depends_on = [
    azurerm_kubernetes_cluster.anmol_cluster
  ]

}

resource "helm_release" "aad_pod_identity" {
  name         = "aad-pod-identity"
  chart        = "aad-pod-identity"
  version      = "2.0.0"
  repository   = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  namespace    = "kube-system"
  create_namespace = true
  max_history  = 4
  atomic       = true
  reuse_values = false
  timeout      = 1800
  values       = [yamlencode(local.aad_pod_identity_settings)]
  depends_on = [
    azurerm_kubernetes_cluster.anmol_cluster
  ]

}

###############################################################