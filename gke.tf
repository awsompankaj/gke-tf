variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}
variable "master_authorized_network_config" {

}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}
variable "machineType" {
  default     = "e2-medium"
  description = "sizing of compute node"
}
# local api whitelisting
locals {
cidr_blocks = concat(var.master_authorized_network_config.cidr_blocks,
[
  {
    display_name : "GKE Cluster CIDR",
    cidr_block : format("%s/32", google_compute_subnetwork.subnet.ip_cidr_range)
  },
]
)
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  ip_allocation_policy {
  cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
  services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range.1.range_name
   }
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  addons_config {
    horizontal_pod_autoscaling {
       disabled  = false
  }
  network_policy_config {
     disabled = false
  }

}
  network_policy {
      enabled  = true
    }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.10.2.0/28"
  }
  master_authorized_networks_config {
  dynamic "cidr_blocks" {
    for_each = [for cidr_block in local.cidr_blocks: {
      display_name = cidr_block.cidr_block
      cidr_block = cidr_block.cidr_block
    }]
    content {
      cidr_block = cidr_blocks.value.cidr_block
      display_name = cidr_blocks.value.display_name

    }
  }
}
  cluster_autoscaling {
       enabled = true
       resource_limits {
           minimum       = 1
           maximum       = 2
           resource_type = "cpu"
        }
       resource_limits {
           minimum       = 1
           maximum       = 2
           resource_type = "memory"
        }
    }

}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = var.machineType
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}


# # Kubernetes provider
# # The Terraform Kubernetes Provider configuration below is used as a learning reference only. 
# # It references the variables and resources provisioned in this file. 
# # We recommend you put this in another file -- so you can have a more modular configuration.
# # https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster#optional-configure-terraform-kubernetes-provider
# # To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider.

# provider "kubernetes" {
#   load_config_file = "false"

#   host     = google_container_cluster.primary.endpoint
#   username = var.gke_username
#   password = var.gke_password

#   client_certificate     = google_container_cluster.primary.master_auth.0.client_certificate
#   client_key             = google_container_cluster.primary.master_auth.0.client_key
#   cluster_ca_certificate = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
# }

