################## PROVIDERS ############################3
provider "google" {
#  project     = "gcp-ushi-search-platform-npe"
  project     = "formal-cabinet-316308"
  region      = "us-east4"
  credentials = "/Users/mrodkin/Documents/gcp/sa-search-datauser-npe.json"
#  credentials = "/Users/mrodkin/Downloads/formal-cabinet-316308-85ef2ad7a746.json"
}

################## DATA ############################3
data "google_container_cluster" "mycluster" {
  name     = "gke-apollo-us-east4-dev"
  location = "us-east4"
}
data "google_client_config" "provider" {}

data "google_compute_network" "vpc_network" {
  name = "gcp-ushi-east4-dgtl-npe-vpc"
}

################## VARS ############################3
variable "project_name" {
  default = "dataset-110474"
}

################## RESOURCE ############################
resource "google_container_cluster" "mycluster" {
  name = "mycluster"
  #location = "us-central1"
  remove_default_node_pool = true
  initial_node_count       = 1
}

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



################## OUTPUT ############################3
output "google_compute_network-default-name" {
  value = google_compute_network.vpc_network.name
}

