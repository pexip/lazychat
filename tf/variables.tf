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

variable "project_id" {
  description = "The project ID to host the cluster in"
  default = "px-sre-homework"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "jb-homework-cluster"
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "europe-north1"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "jb-homework-vpc"
}

variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "jb-homework-subnet"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "jb-homework-ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "jb-homework-ip-range-scv"
}

variable "container_registry_location" {
  description = "The location to use for google container registry"
  default     = "EU"
}

variable "app_name" {
  description = "The name of the app to be run"
  default     = "lazy-chat"
}
variable "name" {
  description = "The name of the app to be run"
  default     = "lazy-chat"
}

variable "gke_oauth_scopes" {
  description = "GCP OAuth scopes for GKE (https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes)"
  type        = list(string)
  default = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring"
  ]
}
