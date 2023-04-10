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

# data "amazon-ami" "base_image" {
#   region = "us-east-1"
#   filters = {
#     name             = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
#     root-device-type = "ebs"
#   }
#   most_recent = true
#   owners      = ["099720109477"]
# }

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
  })
}

source "azure-arm" "myapp" {
  #image_offer                       = "0001-com-ubuntu-server-jammy"
  #image_publisher                   = "Canonical"
  #image_sku                         = "22_04-lts"
  location                          = "East US"
  
  custom_managed_image_name         = data.hcp-packer-image.azure.labels.managed_image_name
  custom_managed_image_resource_group_name = data.hcp-packer-image.azure.labels.managed_image_resourcegroup_name

  managed_image_name                = "${var.image_name}_{{timestamp}}"
  managed_image_resource_group_name = "${var.image_name}"
  
  os_type                           = "Linux"
  vm_size                           = "Standard_DS2_v2"
  subscription_id                   = var.subscription_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  azure_tags = merge(var.default_base_tags, {
    MyTags = "MyAzureTags"
    builddate = formatdate("MMM DD, YYYY", timestamp())
    buildtime = formatdate("HH:mmaa", timestamp())
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
