packer {
  required_version = ">= 1.7.0"
  required_plugins {
    amazon = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

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
  }
}

data "amazon-ami" "base_image" {
  region = "us-east-1"
  filters = {
    name             = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type = "ebs"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "myapp" {
  region         = "us-east-1"
  source_ami     = data.amazon-ami.base_image.id
  instance_type  = "t2.nano"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "hcp_packer_demo_app_{{timestamp}}"
  tags = merge(var.default_base_tags, {
    SourceAMIName = "{{ .SourceAMIName }}"
  })
}

source "azure-arm" "myapp" {
  image_offer                       = "0001-com-ubuntu-server-jammy"
  image_publisher                   = "Canonical"
  image_sku                         = "22_04-lts"
  location                          = "East US"
  managed_image_name                = "hcp_packer_demo_app_{{timestamp}}"
  managed_image_resource_group_name = "hcp_packer_demo_app"
  os_type                           = "Linux"
  vm_size                           = "Standard_DS2_v2"
  subscription_id                   = var.subscription_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  azure_tags = merge(var.default_base_tags, {
    MyTags = "MyAzureTags"
  })
}

build {
    hcp_packer_registry {
      bucket_name = "hcp-packer-myapp"
      description = "Simple static website"

      bucket_labels = var.default_base_tags

      build_labels = {
        "build-time" = timestamp()
        "operating-system" = "Ubuntu"
        "operating-system-release" = "22.04"
        #"owner" = "Troy"
      }
    }

  sources = ["source.amazon-ebs.myapp",
             "source.azure-arm.myapp"]

  // Copy binary to tmp
  provisioner "file" {
    source      = "../bin/server"
    destination = "/tmp/"
  }

  provisioner "shell" {
    script = "./scripts/setup.sh"
  }

  post-processor "manifest" {
    output     = "packer_manifest.json"
    strip_path = true
    custom_data = {
      iteration_id = packer.iterationID
    }
  }
}
