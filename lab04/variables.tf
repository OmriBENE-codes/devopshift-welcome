
variable "environment" {
  description = "Define the environment type: dev, staging, or prod"
  type        = string
  default     = "dev"
}

variable "high_availability" {
  description = "Whether to enable high availability (true or false)"
  type        = bool
  default     = false
}


variable "create_database" {

  description = "Whether to create the database or not"
  type        = bool
  default     = false

}
