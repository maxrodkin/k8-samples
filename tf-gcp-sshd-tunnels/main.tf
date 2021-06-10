################## PROVIDERS ############################3
provider "google" {
  project     = var.project_name
  region      = "us-east4"
  credentials = "/Users/mrodkin/Downloads/formal-cabinet-316308-85ef2ad7a746.json"
}

################## DATA ############################3
data "google_client_config" "provider" {}
data "google_service_account" "default" {
  account_id = "106228516061772265861"
}
################## VARS ############################3
variable "project_name" {
  default = "formal-cabinet-316308"
}

################## RESOURCE ############################
resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}

resource "google_compute_firewall" "default" {
  name    = var.project_name
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["2222", "30000-40000"]
  }

  source_tags = ["web"]
}

resource "google_container_cluster" "mycluster" {
  name                     = "mycluster"
  remove_default_node_pool = true
  initial_node_count       = 1
  location                 =  "us-east4-a"
  #region = "us-east4"
  #node_locations = ["us-east4-a"]
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  #node_locations = ["us-east4-a"]
  location                 =  "us-east4-a"
  #zone = "us-east4-a"
  cluster    = google_container_cluster.mycluster.name
  node_count = 1
  lifecycle {
    ignore_changes = [ initial_node_count ]
  }
  autoscaling {
    max_node_count = 1
    min_node_count = 1
  }
  node_config {
    preemptible  = true
    machine_type = "e2-micro"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = data.google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

################## OUTPUT ############################3
output "google_compute_network-default-name" {
  value = google_compute_network.vpc_network.name
}

