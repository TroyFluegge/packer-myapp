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
  region = "us-east-2"
  filters = {
    name             = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type = "ebs"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "myapp" {
  region         = "us-east-2"
  source_ami     = data.amazon-ami.base_image.id
  instance_type  = "t2.nano"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "hcp_packer_demo_app_{{timestamp}}"
}

source "azure-arm" "myapp" {
  image_offer                       = "UbuntuServer"
  image_publisher                   = "Canonical"
  image_sku                         = "16.04-LTS"
  location                          = "East US"
  managed_image_name                = "hcp_packer_demo_app_{{timestamp}}"
  managed_image_resource_group_name = "hcp_packer_demo_app"
  os_type                           = "Linux"
  vm_size                           = "Standard_DS2_v2"
}

build {
  hcp_packer_registry {
    bucket_name = "hcp-packer-myapp"
    description = "Simple static website"

    bucket_labels = {
      "Team"  = "MyAppTeam"
      "Owner" = "Troy Fluegge"
    }

    build_labels = {
      "build-time" = timestamp()
      "operating-system" = "Ubuntu"
      "operating-system-release" = "22.04"
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