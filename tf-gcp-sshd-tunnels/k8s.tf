################## PROVIDERS ############################3

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

################## RESOURCE ############################

resource "kubernetes_namespace" "namespace" {
  metadata {
    annotations = {
      name = var.project_name
    }
    labels = {
      project = var.project_name
    }
    name = var.project_name
  }

}

resource "kubernetes_deployment" "sshd" {
  metadata {
    name      = "sshd"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = {
      project = var.project_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        project = var.project_name
      }
    }

    template {
      metadata {
        labels = {
          project = var.project_name
        }
      }
      spec {
        container {
          image = "panubo/sshd"
          name  = "sshd"

          //          resources {
          //            requests = {
          //              cpu    = "250m"
          //              memory = "250Mi"
          //            }
          //          }
          port {
            container_port = 22
            host_port      = 2222
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "sshd" {
  metadata {
    name      = "sshd"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" : "Internal"
    }
  }
  spec {
    selector = {
      project = var.project_name
    }
    port {
      port        = 2222
      target_port = 2222
    }
    type = "LoadBalancer"
  }
}

# Create a local variable for the load balancer name.
locals {
  lb_name = split("-", split(".", kubernetes_service.sshd.status.0.load_balancer.0.ingress.0.hostname).0).0
}
