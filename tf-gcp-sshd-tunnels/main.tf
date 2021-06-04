################## PROVIDERS ############################3
provider "google" {
  project     = "gcp-ushi-search-platform-npe"
  region      = "us-east4"
  credentials = "/Users/mrodkin//Documents/gcp/sa-search-datauser-npe.json"
}

################## DATA ############################3
data "google_container_cluster" "my_cluster" {
  name     = "gke-apollo-us-east4-dev"
  location = "us-east4"
}
data "google_client_config" "provider" {}

data "google_compute_network" "default" {
  name = "gcp-ushi-east4-dgtl-npe-vpc"
}

################## VARS ############################3
variable "project_name" {
  default = "dataset-110474"
}

################## RESOURCE ############################
resource "google_compute_firewall" "default" {
  name    = var.project_name
  network = data.google_compute_network.default.name
  depends_on = [data.google_compute_network.default]
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


