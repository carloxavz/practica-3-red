# variables.tf
# Variable sin default = obligatoria. Terraform la pide antes de aplicar.

variable "proyecto" {
  type        = string
  description = "ID del proyecto de Google Cloud"
}

variable "prefijo" {
  type        = string
  description = "Prefijo de los nombres, para no chocar con otros equipos"
}

variable "region" {
  type        = string
  description = "Region donde viven las subredes, el router y el NAT"
  default     = "us-central1"
}

variable "zona" {
  type        = string
  description = "Zona de las dos maquinas. Debe pertenecer a var.region"
  default     = "us-central1-a"
}

variable "tipo_maquina" {
  type        = string
  description = "Tipo de maquina de ambas instancias"
  default     = "e2-micro"
}

variable "cidr_publica" {
  type        = string
  description = "Rango de la subred de aplicacion"
  default     = "10.10.1.0/24"
}

variable "cidr_privada" {
  type        = string
  description = "Rango de la subred de datos. Contiguo al publico y sin solape"
  default     = "10.10.2.0/24"
}
