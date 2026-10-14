variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "ecommerce-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.33" # replace with the newest standard-support version, see below
}