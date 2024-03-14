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

data "hcp-packer-iteration" "base-ubuntu" {
  bucket_name = "hcp-ubuntu-base"
  channel = "production"
}

data "hcp-packer-image" "aws" {
  bucket_name = data.hcp-packer-iteration.base-ubuntu.bucket_name
  iteration_id = data.hcp-packer-iteration.base-ubuntu.id
  cloud_provider = "aws"
  region = "us-east-1"
}

data "hcp-packer-image" "azure" {
  bucket_name = data.hcp-packer-iteration.base-ubuntu.bucket_name
  iteration_id = data.hcp-packer-iteration.base-ubuntu.id
  cloud_provider = "azure"
  region = "East US"
}

source "amazon-ebs" "myapp" {
  region         = "us-east-1"
  source_ami     = data.hcp-packer-image.aws.id
  instance_type  = "t2.nano"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "${var.image_name}_{{timestamp}}"
  tags = merge(var.default_base_tags, {
    SourceAMIName = "{{ .SourceAMIName }}"
    builddate = formatdate("MMM DD, YYYY", timestamp())
    buildtime = formatdate("HH:mmaa", timestamp())
    SourceImageChannel = data.hcp-packer-iteration.base-ubuntu.channel_id
    SourceImageIteration = data.hcp-packer-iteration.base-ubuntu.id
  })
}

source "azure-arm" "myapp" {
  location                          = "East US"
  os_type                           = "Linux"
  vm_size                           = "Standard_DS2_v2"
  subscription_id                   = var.subscription_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret

  # Source Image
  custom_managed_image_name         = data.hcp-packer-image.azure.labels.managed_image_name
  custom_managed_image_resource_group_name = data.hcp-packer-image.azure.labels.managed_image_resourcegroup_name
  
  # Destination Image
  managed_image_name                = "${var.image_name}_{{timestamp}}"
  managed_image_resource_group_name = "${var.image_name}"
  
  azure_tags = merge(var.default_base_tags, {
    SourceImageName = data.hcp-packer-image.azure.labels.managed_image_name
    builddate = formatdate("MMM DD, YYYY", timestamp())
    buildtime = formatdate("HH:mmaa", timestamp())
    SourceImageChannel = data.hcp-packer-iteration.base-ubuntu.channel_id
    SourceImageIteration = data.hcp-packer-iteration.base-ubuntu.id
  })
}

build {
    hcp_packer_registry {
      bucket_name = var.image_name
      description = "Simple static website"

      bucket_labels = var.default_base_tags

      build_labels = {
        "builddate" = formatdate("MMM DD, YYYY", timestamp())
        "buildtime" = formatdate("HH:mmaa", timestamp())
        "operating-system" = "Ubuntu"
        "operating-system-release" = "23.04"
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
