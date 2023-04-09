variable "subscription_id" {
    type        = string
    sensitive   = true
}

variable "client_id" {
    type        = string
    sensitive   = true
}

variable "client_secret" {
    type        = string
    sensitive   = true
}

variable "image_name" {
    type        = string
    default   = "hcp-ubuntu-base"
}

variable "default_base_tags" {
  description = "Required tags for the environment"
  type        = map(string)
  default = {
    owner   = "SRE Team"
    contact = "sre@mydomain.com"
  }
}