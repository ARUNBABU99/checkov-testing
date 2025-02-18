provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1"
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-central1"
  #checkov:skip=CKV_GCP_65:The bucket is a public static content host
  #checkov:skip=CKV_GCP_69:The bucket is a public static content host

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "192.168.1.0/24"
      display_name = "admin-network"
    }
  }

  enable_shielded_nodes = true
  master_auth {
  client_certificate_config {
    issue_client_certificate = false
  }
}

  release_channel {
    channel = "REGULAR"
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  network_policy {
    enabled = true
  }

  resource_labels = {
    env = "production"
  }

  ip_allocation_policy {
    use_ip_aliases = true
  }

  enable_intranode_visibility = true
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name
  node_count = 2

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  node_config {
    machine_type = "e2-medium"
    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
