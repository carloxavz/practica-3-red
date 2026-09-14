
terraform {
  required_providers {
    google = { source = "hashicorp/google" }
  }
}

provider "google" {
  project = var.proyecto
  region  = var.region
}

# La VPC es global. En modo personalizado nace sin subredes.
resource "google_compute_network" "vpc" {
  name                    = "${var.prefijo}-vpc"
  auto_create_subnetworks = false
}

# La subred sí es regional, y es donde las máquinas toman su IP interna.
resource "google_compute_subnetwork" "publica" {
  name          = "${var.prefijo}-sub-publica"
  ip_cidr_range = var.cidr_publica
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_instance" "app" {
  name         = "${var.prefijo}-app"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"
  tags         = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    # la máquina debe quedar en tu subred, no en la default
    subnetwork = "https://www.googleapis.com/compute/v1/projects/nube-2026-ii/regions/us-central1/subnetworks/avendano-sub-publica"
    # un bloque vacío aquí otorga una IP pública efímera
    access_config {}
  }

  metadata_startup_script = file("arranque.sh")
}
