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

variable "default_base_tags" {
  description = "Required tags for the environment"
  type        = map(string)
  default = {
    owner   = "SRE Team"
    contact = "sre@mydomain.com"
    builddate = formatdate("MMM DD, YYYY", timestamp())
    buildtime = formatdate("HH:mmaa", timestamp())
  }
}