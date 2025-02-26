variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true

}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
}
variable "db_host" {
  description = "Database host"
  type        = string
}
variable "db_dialect" {
  description = "Database dialect"
  type        = string
}



variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "aws_instance_type" {
  description = "AWS instance type"
}
variable "gcp_instance_type" {
  description = "GCP instance type"
}
variable "gcp_zone" {
  description = "GCP zone"
}
variable "artifact_path" {
  description = "Path to the artifact"
  type        = string

}