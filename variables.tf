# GCP authentication file
variable "gcp_auth_file" {
  type        = string
  description = "GCP authentication file"
}
# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
}
# define GCP project name
variable "gcp_project" {
  type        = string
  description = "GCP project name"
}

variable "owners_members" {
  type        = list(string)
  description = "List of users to add to the owners group"
}
variable "editors_members" {
  type        = list(string)
  description = "List of users to add to the editors group"
}

