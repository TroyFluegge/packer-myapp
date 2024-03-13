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

data "amazon-ami" "base_image" {
  region = "us-east-1"
  filters = {
    name             = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type = "ebs"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "mybase" {
  region         = "us-east-1"
  source_ami     = data.amazon-ami.base_image.id
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

source "azure-arm" "mybase" {
  image_offer                       = "Ubuntu"
  image_publisher                   = "Canonical"
  image_sku                         = "23_04-lts"
  location                          = "East US"
  managed_image_name                = "${var.image_name}_{{timestamp}}"
  managed_image_resource_group_name = "${var.image_name}"
  #build_resource_group_name         = "${var.image_name}"
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
      description = "Simple base image"

      bucket_labels = var.default_base_tags

      build_labels = {
        "builddate" = formatdate("MMM DD, YYYY", timestamp())
        "buildtime" = formatdate("HH:mmaa", timestamp())
        "operating-system" = "Ubuntu"
        "operating-system-release" = "22.04"
        "owner"   = "SRE Team"
        "contact" = "sre@mydomain.com"
      }
    }
#"source.amazon-ebs.mybase",
  sources = ["source.azure-arm.mybase"]

  provisioner "shell" {
    script = "./scripts/setup.sh"
  }
}
