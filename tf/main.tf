/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.45.0"
    }
  }
}

provider "google" {
  #region  = var.region
  #project  = var.project_id

}

data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 3.1"
  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name   = var.subnetwork
      subnet_ip     = "10.0.0.0/17"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google"
  project_id             = var.project_id
  name                   = var.cluster_name
  regional               = true
  region                 = var.region
  network                = module.gcp-network.network_name
  subnetwork             = module.gcp-network.subnets_names[0]
  ip_range_pods          = var.ip_range_pods_name
  ip_range_services      = var.ip_range_services_name
  create_service_account = false

  node_pools_oauth_scopes = {
    all = []
    default-node-pool = var.gke_oauth_scopes
  }
}

resource "google_container_registry" "registry" {
  project               = var.project_id
  location              = var.container_registry_location
}

#resource "google_storage_bucket_iam_member" "viewer" {
#  bucket = google_container_registry.registry.id
#  role = "roles/storage.objectViewer"
#  member = "user:tf-gke-jb-homework-clu-lqxx@px-sre-homework.iam.gserviceaccount.com"
#  #oauth_scopes = var.gke_oauth_scopes
#}

#resource "google_artifact_registry_repository" "my-repo"     {
#  provider = google-beta
#
#  location = var.region
#  repository_id = "${var.project_id}"
#  description = "Docker repo for ${var.project_id}"
#  format = "DOCKER"
#}

#resource "google_service_account" "repo-account" {
#  provider = google-beta
#
#  account_id   = "tf-gke-jb-homework-clu-lqxx"
#  display_name = "Repository Service Account"
#}

#resource "google_artifact_registry_repository_iam_member" "repo-iam" {
#  provider = google-beta
#
#  location = google_artifact_registry_repository.my-repo.location
#  repository = google_artifact_registry_repository.my-repo.name
#  role   = "roles/artifactregistry.reader"
#  member = "serviceAccount:${google_service_account.repo-account.email}"
#}



resource "kubernetes_deployment" "example" {
  metadata {
    name = var.app_name
    labels = {
      app_name = var.app_name
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app_name = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app_name = var.app_name
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project_id}/${var.app_name}:latest"
          name  = var.app_name
          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
  timeouts {
    create = "400s"
  }
}

resource "helm_release" "ingress-nginx" {
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  name = "ingress-nginx"
}

resource "kubernetes_service" "lazy-chat-service" {
  metadata {
    name = "lazy-chat-service"
    labels = {
      app_name = "lazy-chat"
    }
  }
  spec {
    selector = {
      app_name = "lazy-chat"
    }
    port {
      port = 8080
      target_port = 8080
      protocol = "TCP"
    }
    #type = "ClusterIP"
    type = "NodePort"
  }
  timeouts {
    create = "40s"
  }
}

resource "kubernetes_ingress" "lazy-chat-ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "lazy-chat-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }
  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = "lazy-chat-service"
            service_port = 8080
          }
        }
      }
    }
  }
}


#resource "google_compute_global_address" "default" {
#  project      = var.project_id
#  name         = "${var.app_name}-address"
#  ip_version   = "IPV4"
#  address_type = "EXTERNAL"
#}
#
#resource "google_compute_global_forwarding_rule" "https" {
#  provider   = google-beta
#  project    = var.project_id
#  count      = 1
#  name       = "${var.app_name}-https-rule"
#  target     = google_compute_target_https_proxy.default[0].self_link
#  ip_address = google_compute_global_address.default.address
#  port_range = "443"
#  depends_on = [google_compute_global_address.default]
#
#  labels = var.custom_labels
#}
#
#resource "google_compute_target_https_proxy" "default" {
#  project = var.project_id
#  count   = 1 
#  name    = "${var.app_name}-https-proxy"
#  url_map = var.url_map
#
#  ssl_certificates = var.ssl_certificates
#}

module "nginx-ingress-controller" {
  source = "./terraform-kubernetes-ingress-nginx-controller"
}
