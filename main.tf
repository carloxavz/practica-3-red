
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
  tags         = ["servidor-web"]

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
resource "google_compute_firewall" "app_http" {
  name    = "${var.prefijo}-permitir-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"] # El puerto por defecto para tráfico HTTP (web)
  }

  source_ranges = ["0.0.0.0/0"] # Significa "permitir desde cualquier IP de internet"
  target_tags   = ["servidor-web"] # Asegúrate de que esta sea la misma etiqueta de tu instancia
}

resource "google_compute_firewall" "ssh_iap" {
  name    = "${var.prefijo}-permitir-ssh-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["servidor-web"] 
}
