# main.tf
# Solo la configuracion del proveedor. Los recursos viven en:
#   red.tf       -> VPC, subredes, router y NAT
#   computo.tf   -> las dos maquinas virtuales
#   firewall.tf  -> las reglas de cortafuegos

terraform {
  required_providers {
    google = { source = "hashicorp/google" }
  }
}

provider "google" {
  project = var.proyecto
  region  = var.region
}
